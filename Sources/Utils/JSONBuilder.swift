import Foundation

public protocol JSONBuilding {
  func createJSON(nodes: [JSONRepresentable], edges: [[String: Any]]) throws -> Data
}

public final class JSONBuilder: JSONBuilding {
  public init() {}
  
  public func createJSON(nodes: [JSONRepresentable], edges: [[String: Any]]) throws -> Data {
    let graphJSON: [String: Any] = [
      "nodes": nodes.map { $0.jsonRepresentation },
      "edges": edges
    ]
    
    return try JSONSerialization.data(
      withJSONObject: graphJSON,
      options: [.prettyPrinted, .sortedKeys]
    )
  }
}

