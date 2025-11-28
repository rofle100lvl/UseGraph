import Foundation
import UseGraphCore

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

public struct EdgeWithoutReference: Hashable {
    public let from: Node
    public let to: Node
    
    public init(from: Node, to: Node) {
        self.from = from
        self.to = to
    }
}
