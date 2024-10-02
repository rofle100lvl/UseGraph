import Foundation
import Utils

public struct Edge: CSVRepresentable {
  public var fields: [String] {
    ["Source", "Target", "Type"]
  }
  
  public var csvRepresentation: String {
    source + "," + target + "," + type
  }
  
  let source: String
  let target: String
  let type = "directed"
  
  public init(source: String, target: String) {
    self.source = source
    self.target = target
  }
}
