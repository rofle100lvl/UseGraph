import GraphViz
import Foundation

public final class GraphBuilder {
    public static let shared = GraphBuilder()
    
    private init() { }
    
    public func buildGraph(dependencyGraph: [String: Set<String>], format: Format) {
        var graph = Graph(directed: true)
        let nodes: [String: Node] = dependencyGraph
            .reduce(Set<String>()) { result, element in
                var resultCopy = result
                resultCopy.insert(element.key)
                resultCopy.formUnion(element.value)
                return resultCopy
            }
            .reduce([:]) { result, name in
                var resultCopy = result
                resultCopy[name] = Node(name)
                return resultCopy
            }
        dependencyGraph.forEach { from in
            from.value.forEach { to in
                if let from = nodes[from.key],
                   let to = nodes[to] {
                    graph.append(Edge(from: from, to: to))
                }
            }
        }
        graph.render(using: .fdp, to: format) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                let url = URL(fileURLWithPath: #file).deletingLastPathComponent().appending(path: "Graph.\(format.rawValue)")
                guard var fileContents = String(data: data, encoding: .utf8) else { fatalError() }
                if format == .gv {
                    fileContents = self.removeSecondAndThirdLine(string: fileContents)
                }
                
                print(FileManager.default.createFile(atPath: url.path(), contents: fileContents.data(using: .utf8)))
                Task {
                    System.shared.run("open \(url.path())")
                }
            case .failure(let failure):
                print(failure)
            }
        }
        sleep(240)
    }
    
    private func removeSecondAndThirdLine(string: String) -> String {
        var lines = string.split(separator: "\n")
        lines.removeSubrange(1...2)
        return lines.joined(separator: "\n")
        
    }
}
