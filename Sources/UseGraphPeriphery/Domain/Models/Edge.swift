import Foundation
import UseGraphCore
import Utils

public struct Edge: Hashable {
    public let from: Node
    public let to: Node
    public let references: Set<Reference>
    
    public init(from: Node, to: Node, references: Set<Reference>) {
        self.from = from
        self.to = to
        self.references = references
    }
}

extension Edge: JSONRepresentable {
    public var jsonRepresentation: [String: Any] {
        [
            "source": from.id,
            "target": to.id,
            "type": "directed",
            "references": references.map { ref in
                [
                    "line": ref.line,
                    "file": ref.file,
                    "extensionInfo": ref.extensionInfo ?? ""
                ]
            }
        ]
    }
}

public struct EdgeWithoutReference: Hashable {
    public let from: Node
    public let to: Node
    
    public init(from: Node, to: Node) {
        self.from = from
        self.to = to
    }
}
