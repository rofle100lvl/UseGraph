import Utils

public struct Edge: CSVRepresentable, JSONRepresentable, Codable {
  public var fields: [String] {
    ["id", "source", "target", "type"]
  }
  
  public var csvRepresentation: String {
    let idStr = id.map(String.init) ?? ""
    return idStr + "," + source + "," + target + "," + type
  }
  
  public var jsonRepresentation: [String: Any] {
    var result: [String: Any] = [
      "source": source,
      "target": target,
      "type": type
    ]
    if let id = id {
      result["id"] = id
    }
    return result
  }
  
  let source: String
  let target: String
  let type = "directed"
  public var id: Int?
  
  public init(source: String, target: String, id: Int? = nil) {
    self.source = source
    self.target = target
    self.id = id
  }
}
