
import GraphViz
import Foundation

public enum OutpurtGraphBuilderError: Swift.Error {
    case buildGraphError
}

public protocol OutputGraphBuilding {
  func buildGraphData(graph: Graph, format: Format) async throws -> Data
}

public final class OutputGraphBuilder: OutputGraphBuilding {
  public init() {}
  
  public func buildGraphData(graph: Graph, format: Format) async throws -> Data {
    print("Start building graph...")
    
    return try await withCheckedThrowingContinuation { continuation in
      graph.render(using: .fdp, to: format) { [weak self] result in
        guard self != nil else { return }
        switch result {
        case let .success(data):
          continuation.resume(returning: data)
        case let .failure(failure):
          continuation.resume(throwing: OutpurtGraphBuilderError.buildGraphError)
          print(failure)
        }
      }
    }
  }
}
