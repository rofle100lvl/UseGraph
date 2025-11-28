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

    func presentAsNode() -> Node? {
        let entity = findEntity()
        guard let entity else { return nil }

        // Безопасное извлечение модуля
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
}