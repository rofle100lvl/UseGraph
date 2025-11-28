import Foundation

public protocol ProjectConfigurationProtocol {
    func configureProject(projectPath: String?, schemes: String, indexStore: String?) async throws
    func getConfiguration() -> ProjectConfiguration
}

public struct ProjectConfiguration {
    public let projectPath: String?
    public let schemes: [String]
    public let indexStorePath: String?
    
    public init(projectPath: String?, schemes: [String], indexStorePath: String?) {
        self.projectPath = projectPath
        self.schemes = schemes
        self.indexStorePath = indexStorePath
    }
}