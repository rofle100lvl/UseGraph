import ArgumentParser
import System
import ProjectDrivers
import Foundation
import Configuration
import SourceGraph
import Scan
import Shared
import Utils
import XcodeSupport

public struct UseGraphPeripheryAnalyzeCommand: AsyncParsableCommand {
    public init() {}

    public static let configuration = CommandConfiguration(
        commandName: "monolith_destroyer",
        abstract: "Command to build graph of usage.",
        version: "0.0.1"
    )

    @Option(help: "Path to project (.xcodeproj)")
    var projectPath: String? = nil
    
    @Option(help: "Paths to your monolith")
    var monolithPath: String
    
    @Option(help: "Paths to index store")
    var indexStore: String? = nil

    @Option(help: "Schemes to analyze")
    var schemes: String

    public func run() async throws {
        var projectURL: URL?

        if let projectPath {
            projectURL = URL(string: projectPath)
        }

        guard let projectURL else { 
            throw PathError.pathIsNotCorrect 
        }
        
        // Создание зависимостей
        let projectConfigurationService = ProjectConfigurationService()
        let graphOutputService = GraphOutputService()
        let fileSystemService = FileSystemService()
        
        // Конфигурация проекта
        try await projectConfigurationService.configureProject(
            projectPath: projectPath,
            schemes: schemes,
            indexStore: indexStore
        )
        
        // Создание SourceGraph
        let configuration = Configuration()
        if projectPath != nil {
            configuration.project = .init(projectURL.absoluteString)
            configuration.schemes = schemes.components(separatedBy: ",")
        }
        let project = try Project(configuration: configuration)

        if let indexStore {
            configuration.indexStorePath = [.makeAbsolute(indexStore)]
        } else {
            let driver = try project.driver()
            try driver.build()
        }
        
        let graph = SourceGraph(configuration: configuration, logger: .init())
        
        _ = try Scan(
            configuration: configuration,
            sourceGraph: graph
        ).perform(project: project)
        
        // Создание репозитория и use case
        let sourceGraphRepository = SourceGraphRepository(sourceGraph: graph)
        let analyzeMonolithUseCase = AnalyzeMonolithUseCase(
            sourceGraphRepository: sourceGraphRepository,
            graphOutputService: graphOutputService,
            fileSystemService: fileSystemService
        )
        
        // Выполнение
        let totalEdges = try await analyzeMonolithUseCase.execute(monolithPath: monolithPath)
        print("Total edges processed: \(totalEdges)")
    }
}

public enum PathError: Error {
    case pathIsNotCorrect
    case shouldBeOnlyOnePath

    public var localizedDescription: String {
        switch self {
        case .pathIsNotCorrect:
            return "Path is not correct. Check your path."
        case .shouldBeOnlyOnePath:
            return "You should set strictly one path. Not a zero and not a both of them. Project or folder"
        }
    }
}