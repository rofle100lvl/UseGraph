import Foundation
import GraphViz
import UseGraphCore
import Utils

enum OutputFormat {
    case svg
    case png
    case gv
    
    public static func parse(format: String) throws -> OutputFormat {
        switch format.lowercased() {
        case "svg":
                .svg
        case "png":
                .png
        case "gv":
                .gv
        default:
            throw FormatError.formatIsNotCorrect
        }
    }
}

final class GraphBuilder {
    static let shared = GraphBuilder()
    let csvBuilder: CSVBuilding
    let outputGraphBuilder: OutputGraphBuilding
    
    private init(
        csvBuilder: CSVBuilding = CSVBuilder(),
        outputGraphBuilder: OutputGraphBuilding = OutputGraphBuilder()
    ) {
        self.csvBuilder = csvBuilder
        self.outputGraphBuilder = outputGraphBuilder
    }
    
    func csvBuildGraph(edges: [UseGraphPeriphery.Edge]) {
        var uniqueSet = Set<UseGraphCore.Node>()
        edges.map { [$0.from, $0.to] }.flatMap { $0 }.forEach { uniqueSet.insert($0) }
        
        let edges = edges.map { UseGraphCore.Edge(source: $0.from.id, target: $0.to.id) }
        let edgesCSV = csvBuilder.createCSV(from: edges)
        let nodesCSV = csvBuilder.createCSV(from: Array(uniqueSet))
        
        let nodesUrl = URL(fileURLWithPath: #file).deletingLastPathComponent().appending(path: "Nodes.csv")
        let edgesUrl = URL(fileURLWithPath: #file).deletingLastPathComponent().appending(path: "Edges.csv")
        
        guard let edgesData = edgesCSV.data(using: .utf8),
              let nodesData = nodesCSV.data(using: .utf8) else { fatalError() }
        print(FileManager.default.createFile(atPath: edgesUrl.path(), contents: edgesData))
        print(FileManager.default.createFile(atPath: nodesUrl.path(), contents: nodesData))
    }
    
    func buildGraph(edges: [Edge], format: OutputFormat) async throws {
        switch format {
        case .svg, .png, .gv:
            guard let format = mapFormat(format: format) else { fatalError() }
            let data = try await buildGraphData(edges: edges, format: format)
            let url = URL(fileURLWithPath: #file).deletingLastPathComponent().appending(path: "Graph.\(format.rawValue)")
            guard let fileContents = String(data: data, encoding: .utf8) else { fatalError() }
            
            print(FileManager.default.createFile(atPath: url.path(), contents: fileContents.data(using: .utf8)))
            Task {
                System.shared.run("open \(url.path())")
            }
        }
    }
    
    func buildGraphData(edges: [Edge], format: Format) async throws -> Data {
        var graph = Graph(directed: true)
        
        for edge in edges {
            graph.append(
                GraphViz.Edge(
                    from: GraphViz.Node(edge.from.id),
                    to: GraphViz.Node(edge.to.id)
                )
            )
        }
        
        return try await outputGraphBuilder.buildGraphData(graph: graph, format: format)
    }
}

extension GraphBuilder {
    func mapFormat(format: OutputFormat) -> Format? {
        switch format {
        case .svg:
                .svg
        case .png:
                .png
        case .gv:
                .gv
        }
    }
}
