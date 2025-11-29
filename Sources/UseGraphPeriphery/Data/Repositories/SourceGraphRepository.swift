import Foundation
import SourceGraph
import Configuration
import Scan
import ProjectDrivers
import UseGraphCore

public final class SourceGraphRepository: SourceGraphRepositoryProtocol {
    private let sourceGraph: SourceGraph
    
    public init(sourceGraph: SourceGraph) {
        self.sourceGraph = sourceGraph
    }
    
    public func extractEdges() async throws -> [Edge] {
        var edgeDict: [EdgeWithoutReference: [Reference]] = [:]
        
        sourceGraph.allReferences.forEach { reference in
            guard let declaration = sourceGraph.allDeclarationsByUsr[reference.usr],
                  declaration.parent != reference.parent else { return }
            
            guard let entity = reference.parent?.findEntity(),
                  entity != declaration.findEntity(),
                  let entityParent = entity.presentAsNode(sourceGraph: sourceGraph),
                  let declarationParent = declaration.presentAsNode(sourceGraph: sourceGraph) else { return }
            
            let edge: EdgeWithoutReference
            
            if entity.kind == .protocol && declaration.kind == .functionMethodInstance {
                edge = EdgeWithoutReference(
                    from: declarationParent,
                    to: entityParent
                )
            } else {
                edge = EdgeWithoutReference(
                    from: entityParent,
                    to: declarationParent
                )
            }
            
            // Получаем extensionInfo для declaration (вызываемого метода/свойства)
            let extensionInfo = declaration.getExtensionInfo(sourceGraph: sourceGraph)
            
            if edgeDict[edge] == nil {
                edgeDict[edge] = []
            }
            edgeDict[edge]?.append(
                Reference(
                    line: reference.location.line,
                    file: reference.location.file.path.string,
                    extensionInfo: extensionInfo
                )
            )
        }
        
        return edgeDict.compactMap { keyValue in
            Edge(from: keyValue.key.from, to: keyValue.key.to, references: Set(keyValue.value))
        }
    }
}
