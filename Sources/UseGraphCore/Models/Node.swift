import Utils

public struct Node: Hashable, CSVRepresentable {
    public var csvRepresentation: String {
      var fields = [id, moduleName, fileName]
      if let line {
        fields.append(line)
      }
      if let entityName {
        fields.append(entityName)
      }
      if let entityType {
        fields.append(entityType)
      }
      return fields.joined(separator: ",")
    }

    public var fields: [String] {
      var fields = ["id", "moduleName", "fileName"]
      if line != nil {
        fields.append("line")
      }
      if entityName != nil {
        fields.append("entityName")
      }
      if entityType != nil {
        fields.append("entityType")
      }
      return fields
    }

    public var id: String {
      moduleName + "." + (containerName ?? "") + (entityName ?? "") + "." + (entityType ?? "") + "." + usrs.joined(separator: ",")
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
