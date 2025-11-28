import Foundation
import Utils

public final class AnalyzeMonolithUseCase {
    private let sourceGraphRepository: SourceGraphRepositoryProtocol
    private let graphOutputService: GraphOutputServiceProtocol
    private let fileSystemService: FileSystemServiceProtocol
    
    public init(
        sourceGraphRepository: SourceGraphRepositoryProtocol,
        graphOutputService: GraphOutputServiceProtocol,
        fileSystemService: FileSystemServiceProtocol
    ) {
        self.sourceGraphRepository = sourceGraphRepository
        self.graphOutputService = graphOutputService
        self.fileSystemService = fileSystemService
    }
    
    public func execute(monolithPath: String) async throws -> Int {
        let edges = try await sourceGraphRepository.extractEdges()
        let folderURLs = fileSystemService.findSubdirectories(atPath: monolithPath)
        
        var counter = 0
        for folderPath in folderURLs {
            let edgesInFolder = filterEdgesForFolder(edges: edges, folderPath: folderPath)
            
            guard let url = URL(string: folderPath) else { continue }
            
            let data = try await graphOutputService.buildGraphData(edges: edgesInFolder, format: .svg)
            counter += edgesInFolder.count
            
            let htmlString = generateHTMLReport(edges: edgesInFolder, svgData: data)
            try saveHTMLReport(htmlString: htmlString, url: url)
            
            print("\(folderPath) - \(edgesInFolder.count)")
        }
        
        return counter
    }
    
    private func filterEdgesForFolder(edges: [Edge], folderPath: String) -> [Edge] {
        return edges
            .filter { $0.from.fileName.matches(.init("\(folderPath).*")) }
            .filter { $0.to.fileName.matches("^(?!\(folderPath)).*") && $0.to.moduleName == $0.from.moduleName }
    }
    
    private func generateHTMLReport(edges: [Edge], svgData: Data) -> String {
        let sortedEdges = edges
            .sorted { $0.from.id < $1.from.id }
            .sorted { $0.to.id < $1.to.id }
            .map { edge in
                (
                    edge.from.fileName,
                    edge.from.id,
                    edge.to.fileName,
                    edge.to.id,
                    edge.references.sorted(by: { $0 < $1 }).map { String($0.line) }
                )
            }
        
        return HTMLGenerator.shared.generateHTMLTable(
            withLinks: sortedEdges,
            svgString: String(data: svgData, encoding: .utf8) ?? ""
        )
    }
    
    private func saveHTMLReport(htmlString: String, url: URL) throws {
        guard let edgesData = htmlString.data(using: .utf8) else {
            throw AnalyzeMonolithError.failedToGenerateHTML
        }
        
        FileManager.default.createFile(
            atPath: url.appending(path: "module-info.html").path(),
            contents: edgesData
        )
    }
}

public enum AnalyzeMonolithError: Error {
    case failedToGenerateHTML
    
    public var localizedDescription: String {
        switch self {
        case .failedToGenerateHTML:
            return "Failed to generate HTML report"
        }
    }
}