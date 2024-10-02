import Foundation

public protocol CSVRepresentable {
    var csvRepresentation: String { get }
    var fields: [String] { get }
}
