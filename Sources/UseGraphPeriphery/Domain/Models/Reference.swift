import Foundation
import Utils

public struct Reference: Hashable, Comparable, CSVRepresentable {
    public static func < (lhs: Reference, rhs: Reference) -> Bool {
        lhs.file < rhs.file || lhs.line < rhs.line
    }
    
    public let line: Int
    public let file: String
    public let extensionInfo: String?
    public var edgeId: Int? // Optional for backward compatibility
    
    public init(line: Int, file: String, extensionInfo: String? = nil, edgeId: Int? = nil) {
        self.line = line
        self.file = file
        self.extensionInfo = extensionInfo
        self.edgeId = edgeId
    }
    
    // CSVRepresentable
    public var csvRepresentation: String {
        let fields = [
            edgeId.map(String.init) ?? "",
            String(line),
            file,
            extensionInfo ?? ""
        ]
        return fields.joined(separator: ",")
    }
    
    public var fields: [String] {
        return ["edge_id", "line", "file", "extensionInfo"]
    }
}