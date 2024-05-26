import Foundation
import SwiftSyntax
import SwiftParser
import XcodeProj

public struct ModuleScanResult {
    public let fileScanResult: [String: Node]
    public let moduleName: String
}

public struct FileScanResult {
    public let fileName: String
    public let parametersDependencies: [String: Node]
}

public struct Node: Hashable {
    public let moduleName: String
    public let connectedTo: Set<String>
    
    public init(moduleName: String, connectedTo: Set<String>) {
        self.moduleName = moduleName
        self.connectedTo = connectedTo
    }
}


public enum InitScanner {
    public static func scan(url: URL) async throws -> [ModuleScanResult] {
        var moduleScanResult: [ModuleScanResult] = []
        
        var modules = [Module]()
        
        if url.pathExtension == "xcodeproj" {
            modules = try XcodeprojManager.getAllModules(projUrl: url)
        } else {
            let fileURLs = FileManager.default.allFiles(inDirectory: url)
            modules = [Module(moduleName: "", files: fileURLs)]
        }

        await withTaskGroup(of: ([FileScanResult], String)?.self) { group in
            for module in modules {
                group.addTask {
                    return (await handleModule(module: module), module.moduleName)
                }
            }
            for await entity in group {
                if let entity {
                    if !entity.0.isEmpty {
                        let graph = entity.0
                            .map(\.parametersDependencies)
                            .reduce([String: Node]()) { result, element in
                                
                                result.merging(element, uniquingKeysWith: {
                                    Node(moduleName: $0.moduleName, connectedTo: $0.connectedTo.union($1.connectedTo))
                                })
                            }

                        moduleScanResult.append(ModuleScanResult(fileScanResult: graph, moduleName: entity.1))
                    }
                }
            }
        }
        return moduleScanResult
    }
    
    private static func handleModule(module: Module) async -> [FileScanResult] {
        var fileGraphs = [FileScanResult]()
        print(module.files.count)
        await withTaskGroup(of: ([String: Set<String>], String).self) { group in
            for file in module.files {
                group.addTask {
                    return (await matchPattern(at: file), file.path())
                }
                
            }
            for await entity in group {
                let results = entity.0
                    .reduce([String: Node]()) { result, element in
                        var newResult = result
                        newResult[element.key] = Node(moduleName: module.moduleName, connectedTo: element.value)
                        
                        return newResult
                    }
                fileGraphs.append(FileScanResult(fileName: entity.1, parametersDependencies: results))
            }
        }

        return fileGraphs
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
        let visitor = DefinitionVisitor()
        visitor.walk(rootNode)
        return visitor.graphDependencies
    }
}

extension String {
  func containsRegexPattern(_ pattern: String) -> Bool {
    self.range(of: pattern, options: .regularExpression) != nil
  }
}
