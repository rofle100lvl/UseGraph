import Foundation

public protocol GraphOutputServiceProtocol {
    func buildGraph(edges: [Edge], format: OutputFormat) async throws
    func buildGraphData(edges: [Edge], format: OutputFormat) async throws -> Data
}