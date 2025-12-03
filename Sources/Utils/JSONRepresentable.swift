import Foundation

public protocol JSONRepresentable {
  var jsonRepresentation: [String: Any] { get }
}
