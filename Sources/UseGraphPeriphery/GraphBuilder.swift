import Foundation
import Utils

protocol CSVRepresentable {
    var csvRepresentation: String { get }
    var fields: [String] { get }
}

struct EdgeCSV: CSVRepresentable {
    var fields: [String] {
        ["Source", "Target", "Type"]
    }
    let source: String
    let target: String
    let type = "directed"
    
    var csvRepresentation: String {
        source + "," + target + "," + type
    }
}

public final class GraphBuilder {
    public static let shared = GraphBuilder()
    
    private init() { }
    
    private func createCSV(from recArray: [CSVRepresentable]) -> String {
        guard let fields = recArray.first?.fields else { return "" }
        var csvString = fields.joined(separator: ",") + "\n"
        for dct in recArray {
            csvString = csvString.appending(dct.csvRepresentation + "\n")
        }
        return csvString
    }
    
    public func csvBuildGraph(edges: [Edge]) {
        var uniqueSet = Set<Node>()
        edges.map { [$0.from, $0.to] }.flatMap { $0 }.forEach { uniqueSet.insert($0) }
        
        let edges = edges.map { EdgeCSV(source: $0.from.id, target: $0.to.id) }
        let edgesCSV = createCSV(from: edges)
        let nodesCSV = createCSV(from: Array(uniqueSet))
        
        let nodesUrl = URL(fileURLWithPath: #file).deletingLastPathComponent().appending(path: "Nodes.csv")
        let edgesUrl = URL(fileURLWithPath: #file).deletingLastPathComponent().appending(path: "Edges.csv")

        guard let edgesData = edgesCSV.data(using: .utf8),
              let nodesData = nodesCSV.data(using: .utf8) else { fatalError() }
        print(FileManager.default.createFile(atPath: edgesUrl.path(), contents: edgesData))
        print(FileManager.default.createFile(atPath: nodesUrl.path(), contents: nodesData))
    }
}
