import Utils

public struct Node: Hashable, CSVRepresentable, JSONRepresentable, Codable {
    public var csvRepresentation: String {
      let fields = [
        id,
        moduleName,
        fileName,
        line ?? "",
        entityName ?? "",
        entityType ?? ""
      ]
      return fields.joined(separator: ",")
    }

    public var fields: [String] {
      return ["id", "moduleName", "fileName", "line", "entityName", "entityType"]
    }

    public var jsonRepresentation: [String: Any] {
        [
            "id": id,
            "moduleName": moduleName,
            "fileName": fileName,
            "line": line ?? "",
            "entityName": entityName ?? "",
            "containerName": containerName ?? "",
            "entityType": entityType ?? "",
            "usrs": Array(usrs)
        ]
    }

    public var id: String {
        let baseId = moduleName + "." + (containerName ?? "") + (entityName ?? "") + "." + (entityType ?? "") + "." + usrs.joined(separator: ".")
        let locationId = fileName + ":" + (line ?? "-1")
        return baseId + "@" + locationId
    }

    public let moduleName: String
    public let fileName: String
    public let line: String?
    public let containerName: String?
    public let entityName: String?
    public let entityType: String?
    public let usrs: Set<String>

    public init(
        moduleName: String,
        fileName: String,
        line: String?,
        entityName: String?,
        containerName: String?,
        entityType: String?,
        usrs: Set<String> = Set<String>()
    ) {
        self.moduleName = moduleName
        self.fileName = fileName
        self.line = line
        self.entityName = entityName
        self.containerName = containerName
        self.entityType = entityType
        self.usrs = usrs
    }
}
