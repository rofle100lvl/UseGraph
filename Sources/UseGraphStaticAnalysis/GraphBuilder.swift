import Foundation
import GraphViz
import UseGraphCore
import Utils

public final class GraphBuilder {
  public static let shared = GraphBuilder()
  let csvBuilder: CSVBuilding
  let jsonBuilder: JSONBuilding
  let outputGraphBuilder: OutputGraphBuilding
  
  private init(
    csvBuilder: CSVBuilding = CSVBuilder(),
    jsonBuilder: JSONBuilding = JSONBuilder(),
    outputGraphBuilder: OutputGraphBuilding = OutputGraphBuilder()
  ) {
    self.csvBuilder = csvBuilder
    self.jsonBuilder = jsonBuilder
    self.outputGraphBuilder = outputGraphBuilder
  }
  
  private func prepareGraphData(from dependencyGraph: [String: UseGraphStaticAnalysis.Node]) -> (nodes: [UseGraphCore.Node], edges: [UseGraphCore.Edge]) {
    let nodes: [String: UseGraphCore.Node] = dependencyGraph
      .reduce(Set<String>()) { result, element in
        var resultCopy = result
        resultCopy.insert(element.key)
        resultCopy.formUnion(element.value.connectedTo)
        return resultCopy
      }
      .reduce([:]) { result, name in
        var resultCopy = result
        let moduleName = dependencyGraph[name]?.moduleName ?? ""
        let node = UseGraphCore.Node(
          moduleName: moduleName,
          fileName: dependencyGraph[name]?.fileName ?? "",
          line: nil,
          entityName: name,
          containerName: nil,
          entityType: nil
        )
        resultCopy[name] = node
        return resultCopy
      }
    
    let edges = dependencyGraph.reduce([UseGraphCore.Edge]()) { result, element in
      var newResult = result
      
      newResult.append(
        contentsOf: element.value.connectedTo.compactMap { to in
          if let from = nodes[element.key],
             let to = nodes[to]
          {
            return UseGraphCore.Edge(source: from.id, target: to.id)
          }
          return nil
        }
      )
      return newResult
    }
    
    return (nodes.map { $0.value }, edges)
  }
  
  private func csvBuildGraph(dependencyGraph: [String: UseGraphStaticAnalysis.Node]) {
    let (nodes, edges) = prepareGraphData(from: dependencyGraph)
    
    let edgesCSV = csvBuilder.createCSV(from: edges)
    let nodesCSV = csvBuilder.createCSV(from: nodes)
    
    let nodesUrl = URL(fileURLWithPath: #file).deletingLastPathComponent().appending(path: "Nodes.csv")
    let edgesUrl = URL(fileURLWithPath: #file).deletingLastPathComponent().appending(path: "Edges.csv")
    
    guard let edgesData = edgesCSV.data(using: .utf8),
          let nodesData = nodesCSV.data(using: .utf8) else { fatalError() }
    print(FileManager.default.createFile(atPath: edgesUrl.path(), contents: edgesData))
    print(FileManager.default.createFile(atPath: nodesUrl.path(), contents: nodesData))
  }
  
  private func jsonBuildGraph(dependencyGraph: [String: UseGraphStaticAnalysis.Node]) throws {
    let (nodes, edges) = prepareGraphData(from: dependencyGraph)
    
    let edgesJSON = edges.map { $0.jsonRepresentation }
    let jsonData = try jsonBuilder.createJSON(nodes: nodes, edges: edgesJSON)
    
    let jsonUrl = URL(fileURLWithPath: #file).deletingLastPathComponent().appending(path: "Graph.json")
    print(FileManager.default.createFile(atPath: jsonUrl.path(), contents: jsonData))
  }
  
  public func buildGraph(dependencyGraph: [String: UseGraphStaticAnalysis.Node], format: OutputFormat) async throws {
    switch format {
    case .svg, .png, .gv:
      guard let format = mapFormat(format: format) else { fatalError() }
      
      let data = try await buildGraphData(dependencyGraph: dependencyGraph, format: format)
      let url = URL(fileURLWithPath: #file).deletingLastPathComponent().appending(path: "Graph.\(format.rawValue)")
      guard let fileContents = String(data: data, encoding: .utf8) else { fatalError() }
      
      print(FileManager.default.createFile(atPath: url.path(), contents: fileContents.data(using: .utf8)))
      Task {
        System.shared.run("open \(url.path())")
      }
    case .csv:
      csvBuildGraph(dependencyGraph: dependencyGraph)
    case .json:
      try jsonBuildGraph(dependencyGraph: dependencyGraph)
    }
  }
  
  public func buildGraphData(dependencyGraph: [String: UseGraphStaticAnalysis.Node], format: Format) async throws -> Data {
    var graph = Graph(directed: true)
    
    let nodes: [String: GraphViz.Node] = dependencyGraph
      .reduce(Set<String>()) { result, element in
        var resultCopy = result
        resultCopy.insert(element.key)
        resultCopy.formUnion(element.value.connectedTo)
        return resultCopy
      }
      .reduce([:]) { result, name in
        var resultCopy = result
        var node = GraphViz.Node(name)
        if let moduleName = dependencyGraph[name]?.moduleName {
          node.id = moduleName + "." + name
          node.label = moduleName
        }
        resultCopy[name] = node
        return resultCopy
      }
    
    for from in dependencyGraph {
      for to in from.value.connectedTo {
        if let from = nodes[from.key],
           let to = nodes[to]
        {
          graph.append(GraphViz.Edge(from: from.id, to: to.id))
        }
      }
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
    case .csv, .json:
      nil
    }
  }
}
