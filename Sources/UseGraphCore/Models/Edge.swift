import Utils

public struct Edge: CSVRepresentable, JSONRepresentable, Codable {
  public var fields: [String] {
    ["Source", "Target", "Type"]
  }
  
  public var csvRepresentation: String {
    source + "," + target + "," + type
  }
  
  public var jsonRepresentation: [String: Any] {
    [
      "source": source,
      "target": target,
      "type": type
    ]
  }
  
  let source: String
  let target: String
  let type = "directed"
  
  public init(source: String, target: String) {
    self.source = source
    self.target = target
  }
}
