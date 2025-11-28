import Foundation
import GraphViz
import UseGraphCore
import Utils

public final class GraphOutputService: GraphOutputServiceProtocol {
    private let csvBuilder: CSVBuilding
    private let outputGraphBuilder: OutputGraphBuilding
    
    public init(
        csvBuilder: CSVBuilding = CSVBuilder(),
        outputGraphBuilder: OutputGraphBuilding = OutputGraphBuilder()
    ) {
        self.csvBuilder = csvBuilder
        self.outputGraphBuilder = outputGraphBuilder
    }
    
    public func buildGraph(edges: [Edge], format: OutputFormat) async throws {
        switch format {
        case .svg, .png, .gv:
            guard let graphVizFormat = mapToGraphVizFormat(format: format) else {
                throw OutputFormatError.formatIsNotCorrect
            }
            let data = try await buildGraphData(edges: edges, format: format)
            let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appending(path: "Graph.\(graphVizFormat.rawValue)")
            FileManager.default.createFile(atPath: url.path(), contents: data)
            System.shared.run("open \(url.path())")
        case .csv:
            try buildCSVGraph(edges: edges)
        }
    }
    
    public func buildGraphData(edges: [Edge], format: OutputFormat) async throws -> Data {
        guard let graphVizFormat = mapToGraphVizFormat(format: format) else {
            throw OutputFormatError.formatIsNotCorrect
        }
        
        var graph = Graph(directed: true)
        
        for edge in edges {
            graph.append(
                GraphViz.Edge(
                    from: GraphViz.Node(edge.from.id),
                    to: GraphViz.Node(edge.to.id)
                )
            )
        }
        
        return try await outputGraphBuilder.buildGraphData(graph: graph, format: graphVizFormat)
    }
    
    private func buildCSVGraph(edges: [Edge]) throws {
        var uniqueSet = Set<UseGraphCore.Node>()
        edges.map { [$0.from, $0.to] }.flatMap { $0 }.forEach { uniqueSet.insert($0) }
        
        let coreEdges = edges.map { UseGraphCore.Edge(source: $0.from.id, target: $0.to.id) }
        let edgesCSV = csvBuilder.createCSV(from: coreEdges)
        let nodesCSV = csvBuilder.createCSV(from: Array(uniqueSet))
        
        let nodesUrl = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appending(path: "Nodes.csv")
        let edgesUrl = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appending(path: "Edges.csv")
        
        guard let edgesData = edgesCSV.data(using: .utf8),
              let nodesData = nodesCSV.data(using: .utf8) else {
            throw OutputFormatError.formatIsNotCorrect
        }
        
        FileManager.default.createFile(atPath: edgesUrl.path(), contents: edgesData)
        FileManager.default.createFile(atPath: nodesUrl.path(), contents: nodesData)
    }
    
    private func mapToGraphVizFormat(format: OutputFormat) -> Format? {
        switch format {
        case .svg:
            return .svg
        case .png:
            return .png
        case .gv:
            return .gv
        case .csv:
            return nil
        }
    }
}