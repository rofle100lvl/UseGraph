import Foundation
import SwiftSyntax
import SwiftParser

extension String {
  func removingPrefix(_ prefix: String) -> String {
    guard self.hasPrefix(prefix) else { return self }
    var urlString = String(self.dropFirst(prefix.count))
    if urlString.hasPrefix("/") {
      urlString = String(urlString.dropFirst())
    }
    return urlString
  }
}

public struct ScanResult {
    public let fileName: String
    public let parametersDependencies: [String: Set<String>]
}

public enum InitScanner {
    public static func scan(url: URL) async -> [ScanResult] {
        var filesToOptimize: [ScanResult] = []
        
        let fileURLs = FileManager.default.allFiles(inDirectory: url)

        await withTaskGroup(of: ([String: Set<String>], String)?.self) { group in
            for fileURL in fileURLs {
                group.addTask {
                    return (await matchPattern(at: fileURL), fileURL.absoluteString.removingPrefix("file://"))
                }
            }
            for await result in group {
                if let result {
                    if !result.0.isEmpty {
                        filesToOptimize.append(
                            ScanResult(
                                fileName: result.1,
                                parametersDependencies: result.0
                            )
                        )
                    }
                }
            }
        }
        return filesToOptimize
    }
    
    private static func matchPattern(at fileURL: URL) async -> [String: Set<String>] {
        guard fileURL.pathExtension == "swift",
              let fileContent = try? String(contentsOf: fileURL) else {
            return [:]
        }
        do {
            return try findDependencies(dir: fileURL)
        } catch {
            return [:]
        }
    }

    private static func findDependencies(dir: URL) throws -> [String: Set<String>] {
        let text = try String(contentsOf: dir, encoding: .utf8)
        let rootNode: SourceFileSyntax = Parser.parse(source: text)
        let visitor = DefinitionVisitor(converter: SourceLocationConverter(fileName: dir.absoluteString, tree: rootNode))
        visitor.walk(rootNode)
        return visitor.graphDependencies
    }
}

extension String {
  func containsRegexPattern(_ pattern: String) -> Bool {
    self.range(of: pattern, options: .regularExpression) != nil
  }
}
