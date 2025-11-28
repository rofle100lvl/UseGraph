import Foundation
import Configuration
import ProjectDrivers
import SourceGraph
import Scan
import Shared

public final class ProjectConfigurationService: ProjectConfigurationProtocol {
    private var configuration: ProjectConfiguration?
    
    public init() {}
    
    public func configureProject(projectPath: String?, schemes: String, indexStore: String?) async throws {
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
        
        self.configuration = ProjectConfiguration(
            projectPath: projectPath,
            schemes: schemes.components(separatedBy: ","),
            indexStorePath: indexStore
        )
    }
    
    public func getConfiguration() -> ProjectConfiguration {
        guard let configuration = configuration else {
            fatalError("Configuration not set. Call configureProject first.")
        }
        return configuration
    }
}