import ArgumentParser
import Foundation
import UseGraphCore

enum PathError: Error {
    case pathIsNotCorrect
}

@main
public struct UseGraphCommand: AsyncParsableCommand {
    public init() { }
    
    public static let configuration = CommandConfiguration(
        commandName: "usage_graph",
        abstract: "Command to build graph of usage.",
        version: "0.0.1"
    )
    
    @Argument
    var path: String
    
    @Argument
    var format: String = "svg"
    
    @Option(help: ArgumentHelp(stringLiteral: "Путь к сорасам, на которых вы хотите дообучить модель"))
    var educationalPath: String? = nil
    
    @Flag
    var showLastChildren: Bool = false
    
    @Option
    var excludedNames: String? = nil

    public func run() async throws {
        guard let url = URL(string: path) else {
            throw PathError.pathIsNotCorrect
        }
        
        let format = try OutputFormat.parse(format: format)
        
        var scanResults = await InitScanner.scan(url: url)
            .map(\.parametersDependencies)
            .reduce([String: Set<String>]()) { result, element in
                result.merging(element, uniquingKeysWith: {
                    $0.union($1)
                })
            }
        
        if let educationalPath,
           let url = URL(string: educationalPath) {
            let fullScanResults = await InitScanner.scan(url: url)
                .map(\.parametersDependencies)
                .reduce([String: Set<String>]()) { result, element in
                    result.merging(element, uniquingKeysWith: {
                        $0.union($1)
                    })
                }
            
            scanResults = unionDesigns(scanResults: scanResults, fullScanResults: fullScanResults)
        }
        
        if let excludedNames {
            excludedNames.split(separator: ", ").forEach {
                scanResults.removeValue(forKey: String($0))
            }
        }
        var results = scanResults
        
        if !showLastChildren {
            results = scanResults
                .reduce([String: Set<String>]()) { result, element in
                    var newResult = result
                    let usedNodes = element.value.filter { scanResults.keys.contains($0) }
                    newResult[element.key] = usedNodes
                    return newResult
                }
        }
        
        results = results
            .reduce([String: Set<String>]()) { result, element in
                var newResult = result
                var set = element.value
                for to in set {
                    if results.keys.contains(where: { $0 == element.key.appending(".").appending(to) }) {
                        set.remove(to)
                        set.insert(element.key.appending(".").appending(to))
                    }
                }
                newResult[element.key] = set
                return newResult
            }
        
        GraphBuilder.shared.buildGraph(dependencyGraph: results, format: format.toFormat())
    }
    
    func unionDesigns(scanResults: [String: Set<String>], fullScanResults: [String: Set<String>]) -> [String: Set<String>] {
        var scanResultsCopy = scanResults
        var notFound = true
        repeat {
            notFound = true
            scanResultsCopy.forEach { element in
                element.value.forEach { to in
                    if !scanResultsCopy.keys.contains(to) && fullScanResults.keys.contains(to) {
                        scanResultsCopy[to] = fullScanResults[to]
                        notFound = false
                    }
                }
            }
        } while(!notFound)
        return scanResultsCopy
    }
}
