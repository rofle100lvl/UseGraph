import ArgumentParser
import Foundation
import PeripheryKit
import Shared
import XcodeSupport

public struct Edge {
    let from: Node
    let to: Node
    let line: Int?
    let file: String
}

public struct Node: Hashable, CSVRepresentable {
    var csvRepresentation: String {
        [moduleName, fileName, line, entityName ?? "", entityType ?? "", moduleName + id].joined(separator: ",")
    }
    
    var fields: [String] {
        ["moduleName", "fileName", "line", "entityName", "entityType", "id"]
    }

    var id: String {
        moduleName + "." + (entityName ?? "") + "." + (entityType ?? "")
    }
 
    public let moduleName: String
    public let fileName: String
    public let line: String
    public let entityName: String?
    public let entityType: String?
    
    public init(
        moduleName: String,
        fileName: String,
        line: String,
        entityName: String?,
        entityType: String?
    ) {
        self.moduleName = moduleName
        self.fileName = fileName
        self.line = line
        self.entityName = entityName
        self.entityType = entityType
    }
}

enum PathError: Error {
    case pathIsNotCorrect
    case shouldBeOnlyOnePath
    
    var localizedDescription: String {
        switch self {
        case .pathIsNotCorrect:
            "Path is not correct. Check your path."
        case .shouldBeOnlyOnePath:
            "You should set strictly one path. Not a zero and not a both of them. Project or folder"
        }
    }
    
    @main
    public struct UseGraphCommand: AsyncParsableCommand {
        public init() { }
        
        public static let configuration = CommandConfiguration(
            commandName: "usage_graph",
            abstract: "Command to build graph of usage.",
            version: "0.0.1"
        )
        
        @Option(help: "Path to project (.xcodeproj)")
        var projectPath: String? = nil

        public func run() async throws {
            Configuration.shared.workspace = projectPath
            Configuration.shared.schemes = ["App"]
            if let projectPath {
                Configuration.shared.targets = ["TA"]
            }
            let driver = try XcodeProjectDriver.build()
            try driver.build()
            
            let graph = SourceGraph.shared
            try driver.index(graph: graph)
            
            var edges: [Edge] = []
                        
            edges = graph.allReferences
                .compactMap {
                    if let declaration = graph.allExplicitDeclarationsByUsr[$0.usr],
                       declaration.parent != $0.parent {
                        
                        guard let entity = $0.parent?.findEntity() else { return nil }
                        return Edge(
                            from: entity.presentAsNode(),
                            to: declaration.presentAsNode(),
                            line: $0.location.line,
                            file: $0.location.file.path.string
                        )
                    }
                    return nil
                }
            
            GraphBuilder.shared.csvBuildGraph(edges: edges)
        }
    }
}

extension Declaration {
    func findEntity() -> Declaration? {
        var parent: Declaration? = self
        while (parent != nil) &&
                parent?.kind != .class &&
                parent?.kind != .enum &&
                parent?.kind != .struct &&
                parent?.kind != .extension &&
                parent?.kind != .protocol &&
                parent?.kind != .typealias &&
                parent?.kind != .extensionEnum &&
                parent?.kind != .extensionStruct &&
                parent?.kind != .extensionClass &&
                parent?.kind != .extensionProtocol
        {
            parent = parent?.parent
        }
        return parent
    }
    
    func presentAsNode() -> Node {
        let entity = findEntity()
        return Node(
            moduleName: location.file.modules.first!,
            fileName: location.file.path.string,
            line: String(location.line),
            entityName: entity?.name,
            entityType: entity?.kind.rawValue
        )
    }
}
