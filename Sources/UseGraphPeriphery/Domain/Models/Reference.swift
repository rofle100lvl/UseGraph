import Foundation
import Utils

public struct Reference: Hashable, Comparable, CSVRepresentable {
    public static func < (lhs: Reference, rhs: Reference) -> Bool {
        lhs.file < rhs.file || lhs.line < rhs.line
    }
    
    public let line: Int
    public let file: String
    public let extensionInfo: String?
    
    public init(line: Int, file: String, extensionInfo: String? = nil) {
        self.line = line
        self.file = file
        self.extensionInfo = extensionInfo
    }
    
    // CSVRepresentable
    public var csvRepresentation: String {
        let fields = [
            String(line),
            file,
            extensionInfo ?? ""
        ]
        return fields.joined(separator: ",")
    }
    
    public var fields: [String] {
        return ["line", "file", "extensionInfo"]
    }
}