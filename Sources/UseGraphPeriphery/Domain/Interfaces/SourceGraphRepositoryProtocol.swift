import Foundation
import UseGraphCore

public protocol SourceGraphRepositoryProtocol {
    func extractEdges() async throws -> [Edge]
}