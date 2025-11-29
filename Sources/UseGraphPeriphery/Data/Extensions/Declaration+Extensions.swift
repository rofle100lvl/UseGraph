import Foundation
import SourceGraph
import UseGraphCore

extension Declaration {
    func findEntity() -> Declaration? {
        var parent: Declaration? = self
        while parent != nil,
              parent?.kind != .class,
              parent?.kind != .enum,
              parent?.kind != .struct,
              parent?.kind != .extension,
              parent?.kind != .protocol,
              parent?.kind != .typealias,
              parent?.kind != .extensionEnum,
              parent?.kind != .extensionStruct,
              parent?.kind != .extensionClass,
              parent?.kind != .extensionProtocol
        {
            parent = parent?.parent
        }
        return parent
    }
    
    private func isExtensionKind(_ kind: Declaration.Kind) -> Bool {
        return kind == .extension ||
               kind == .extensionEnum ||
               kind == .extensionStruct ||
               kind == .extensionClass ||
               kind == .extensionProtocol
    }
    
    private func findParentExtension() -> Declaration? {
        var parent: Declaration? = self.parent
        while let currentParent = parent {
            if isExtensionKind(currentParent.kind) {
                return currentParent
            }
            parent = currentParent.parent
        }
        return nil
    }
    
    private func extractExtensionInfo(from extensionDecl: Declaration, sourceGraph: SourceGraph) -> String? {
        // Find the extended type in the extensions dictionary
        for (extendedDecl, extensionSet) in sourceGraph.extensions {
            if extensionSet.contains(extensionDecl) {
                return "extension:\(extendedDecl.name ?? "Unknown"):\(extensionDecl.kind.rawValue):\(extensionDecl.location.line)"
            }
        }
        
        // If not found in dictionary, use the extension's own name
        return "extension:\(extensionDecl.name ?? "Unknown"):\(extensionDecl.kind.rawValue):\(extensionDecl.location.line)"
    }
    
    private func findExtensionByLocation(for declaration: Declaration, in sourceGraph: SourceGraph) -> Declaration? {
        guard let parent = declaration.parent else { return nil }
        
        // Check if parent has extensions
        guard let extensionSet = sourceGraph.extensions[parent] else { return nil }
        
        let declFile = declaration.location.file.path.string
        let declLine = declaration.location.line
        
        // Find extension in the same file that starts before the declaration
        var bestMatch: Declaration? = nil
        var bestMatchLine = 0
        
        for ext in extensionSet {
            let extFile = ext.location.file.path.string
            let extLine = ext.location.line
            
            // Extension must be in the same file and start before the declaration
            if extFile == declFile && extLine < declLine && extLine > bestMatchLine {
                bestMatch = ext
                bestMatchLine = extLine
            }
        }
        
        return bestMatch
    }

    func presentAsNode(sourceGraph: SourceGraph? = nil) -> Node? {
        let entity = findEntity()
        guard let entity else { return nil }

        let moduleName = entity.location.file.modules.first ?? "UnknownModule"

        return Node(
            moduleName: moduleName,
            fileName: entity.location.file.path.string,
            line: String(entity.location.line),
            entityName: entity.name,
            containerName: entity.parent?.name,
            entityType: entity.kind.rawValue,
            usrs: entity.usrs
        )
    }
    
    func getExtensionInfo(sourceGraph: SourceGraph) -> String? {
        // First try to find extension through parent hierarchy
        if let parentExtension = findParentExtension() {
            return extractExtensionInfo(from: parentExtension, sourceGraph: sourceGraph)
        }
        // If not found through parent, try to find by location
        else if let extensionByLocation = findExtensionByLocation(for: self, in: sourceGraph) {
            return extractExtensionInfo(from: extensionByLocation, sourceGraph: sourceGraph)
        }
        return nil
    }
}