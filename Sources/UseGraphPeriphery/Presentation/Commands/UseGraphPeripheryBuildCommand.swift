import ArgumentParser
import ProjectDrivers
import Foundation
import PeripheryKit
import SourceGraph
import Configuration
import Scan
import UseGraphCore
import Shared
import XcodeSupport

public struct UseGraphPeripheryBuildCommand: AsyncParsableCommand {
    public init() {}

    public static let configuration = CommandConfiguration(
        commandName: "usage_graph",
        abstract: "Command to build graph of usage.",
        version: "0.0.1"
    )

    @Option(help: "Path to project (.xcodeproj)")
    var projectPath: String? = nil

    @Option(help: "Schemes to analyze")
    var schemes: String
    
    @Option(help: "Paths to index store")
    var indexStore: String? = nil
    
    @Option(help: "Output file format. Now available: CSV, SVG, PNG, GV, JSON")
    var format: String = "csv"

    public func run() async throws {
        // Создание зависимостей
        let projectConfigurationService = ProjectConfigurationService()
        let graphOutputService = GraphOutputService()
        
        // Конфигурация проекта
        try await projectConfigurationService.configureProject(
            projectPath: projectPath,
            schemes: schemes,
            indexStore: indexStore
        )
        
        // Создание SourceGraph
        let configuration = Configuration()
        if let projectPath {
            configuration.project = .init(projectPath)
            configuration.schemes = schemes.components(separatedBy: ",")
        }

        let project = try Project(configuration: configuration)

        if let indexStore {
            configuration.indexStorePath = [.makeAbsolute(indexStore)]
        } else {
            let driver = try project.driver()
            try driver.build()
        }
        
        let graph = SourceGraph(configuration: configuration, logger: .init(quiet: true))
        
        _ = try Scan(
            configuration: configuration,
            sourceGraph: graph
        ).perform(project: project)
        
        // Создание репозитория и use case
        let sourceGraphRepository = SourceGraphRepository(sourceGraph: graph)
        let buildGraphUseCase = BuildGraphUseCase(
            sourceGraphRepository: sourceGraphRepository,
            graphOutputService: graphOutputService
        )
        
        // Выполнение
        let outputFormat = try OutputFormat.parse(format: format)
        try await buildGraphUseCase.execute(format: outputFormat)
    }
}