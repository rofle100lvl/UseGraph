import ArgumentParser
import UseGraphStaticAnalysis
import Foundation
import UseGraphPeriphery

public struct UseGraphFrontendCommand: AsyncParsableCommand {
    public init() {}

    public static let configuration = CommandConfiguration(
        commandName: "use_graph",
        abstract: "Swift CLI to work with Use Graph tool",
        version: "0.0.1",
        subcommands: [
            UseGraphBuildCommand.self,
            UseGraphAnalyzeCommand.self,
            UseGraphPeripheryAnalyzeCommand.self,
            UseGraphPeripheryBuildCommand.self
        ]
    )
}
