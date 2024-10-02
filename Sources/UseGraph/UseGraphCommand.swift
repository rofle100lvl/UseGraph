import ArgumentParser
import UseGraphFrontend

@main
public struct UseGraphCommand: AsyncParsableCommand {
    public init() {}

    public static let configuration = CommandConfiguration(
        commandName: "",
        abstract: "Swift CLI to work with Use Graph tool",
        version: "0.0.1",
        subcommands: [
            UseGraphFrontendCommand.self,
        ]
    )
}
