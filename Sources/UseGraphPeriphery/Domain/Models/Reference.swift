import Foundation

public struct Reference: Hashable, Comparable {
    public static func < (lhs: Reference, rhs: Reference) -> Bool {
        lhs.file < rhs.file || lhs.line < rhs.line
    }
    
    public let line: Int
    public let file: String
    
    public init(line: Int, file: String) {
        self.line = line
        self.file = file
    }
}