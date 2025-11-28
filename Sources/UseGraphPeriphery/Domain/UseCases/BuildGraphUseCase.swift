import Foundation

public final class BuildGraphUseCase {
    private let sourceGraphRepository: SourceGraphRepositoryProtocol
    private let graphOutputService: GraphOutputServiceProtocol
    
    public init(
        sourceGraphRepository: SourceGraphRepositoryProtocol,
        graphOutputService: GraphOutputServiceProtocol
    ) {
        self.sourceGraphRepository = sourceGraphRepository
        self.graphOutputService = graphOutputService
    }
    
    public func execute(format: OutputFormat) async throws {
        let edges = try await sourceGraphRepository.extractEdges()
        try await graphOutputService.buildGraph(edges: edges, format: format)
    }
}