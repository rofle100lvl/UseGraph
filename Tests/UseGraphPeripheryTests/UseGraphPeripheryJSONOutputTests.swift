import XCTest
import Foundation
import SourceGraph
import Configuration
import ProjectDrivers
import Scan
import Shared
import UseGraphCore
@testable import UseGraphPeriphery

final class UseGraphPeripheryJSONOutputTests: XCTestCase {
    
    var testProjectPath: String!
    var originalWorkingDirectory: String!
    var tempDirectory: URL!
    
    override func setUp() {
        super.setUp()
        originalWorkingDirectory = FileManager.default.currentDirectoryPath
        
        // Создаем временную директорию для JSON файлов
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        let currentFile = #file
        let testDir = URL(fileURLWithPath: currentFile)
            .deletingLastPathComponent()
            .appendingPathComponent("TestProject")
            .appendingPathComponent("MyExtensionLibrary")
        testProjectPath = testDir.path
        
        FileManager.default.changeCurrentDirectoryPath(testProjectPath)
    }
    
    override func tearDown() {
        // Очищаем временную директорию
        try? FileManager.default.removeItem(at: tempDirectory)
        FileManager.default.changeCurrentDirectoryPath(originalWorkingDirectory)
        super.tearDown()
    }
    
    func testJSONOutputContainsNodes() async throws {
        // Arrange
        let configuration = Configuration()
        let project = try Project(configuration: configuration)
        let driver = try project.driver()
        try driver.build()
        
        let graph = SourceGraph(configuration: configuration, logger: .init(quiet: true))
        _ = try Scan(configuration: configuration, sourceGraph: graph).perform(project: project)
        
        let sourceGraphRepository = SourceGraphRepository(sourceGraph: graph)
        let graphOutputService = GraphOutputService()
        
        let edges = try await sourceGraphRepository.extractEdges()
        
        // Переходим во временную директорию для создания JSON
        FileManager.default.changeCurrentDirectoryPath(tempDirectory.path)
        
        // Act
        try await graphOutputService.buildGraph(edges: edges, format: .json)
        
        // Assert
        let jsonURL = tempDirectory.appendingPathComponent("Graph.json")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: jsonURL.path), "Graph.json should be created")
        
        // Читаем содержимое Graph.json
        let jsonData = try Data(contentsOf: jsonURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
        
        XCTAssertNotNil(jsonObject, "JSON should be valid")
        
        // Проверяем структуру JSON
        XCTAssertTrue(jsonObject?.keys.contains("nodes") ?? false, "JSON should contain 'nodes' key")
        XCTAssertTrue(jsonObject?.keys.contains("edges") ?? false, "JSON should contain 'edges' key")
        
        // Проверяем nodes
        guard let nodes = jsonObject?["nodes"] as? [[String: Any]] else {
            XCTFail("Nodes should be an array of dictionaries")
            return
        }
        
        XCTAssertGreaterThan(nodes.count, 0, "Should have at least one node")
        
        // Проверяем структуру узла
        if let firstNode = nodes.first {
            XCTAssertTrue(firstNode.keys.contains("id"), "Node should have 'id' field")
            XCTAssertTrue(firstNode.keys.contains("moduleName"), "Node should have 'moduleName' field")
            XCTAssertTrue(firstNode.keys.contains("fileName"), "Node should have 'fileName' field")
            XCTAssertTrue(firstNode.keys.contains("line"), "Node should have 'line' field")
            XCTAssertTrue(firstNode.keys.contains("entityName"), "Node should have 'entityName' field")
            XCTAssertTrue(firstNode.keys.contains("containerName"), "Node should have 'containerName' field")
            XCTAssertTrue(firstNode.keys.contains("entityType"), "Node should have 'entityType' field")
            XCTAssertTrue(firstNode.keys.contains("usrs"), "Node should have 'usrs' field")
        }
        
        // Проверяем edges
        guard let edgesArray = jsonObject?["edges"] as? [[String: Any]] else {
            XCTFail("Edges should be an array of dictionaries")
            return
        }
        
        XCTAssertGreaterThan(edgesArray.count, 0, "Should have at least one edge")
        
        // Проверяем структуру ребра
        if let firstEdge = edgesArray.first {
            XCTAssertTrue(firstEdge.keys.contains("source"), "Edge should have 'source' field")
            XCTAssertTrue(firstEdge.keys.contains("target"), "Edge should have 'target' field")
            XCTAssertTrue(firstEdge.keys.contains("type"), "Edge should have 'type' field")
            
            if let type = firstEdge["type"] as? String {
                XCTAssertEqual(type, "directed", "Edge type should be 'directed'")
            }
        }
        
        // Выводим содержимое для отладки
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("\n📄 Graph.json content:")
            print(jsonString)
        }
        
        print("\n📊 JSON Statistics:")
        print("  Total nodes: \(nodes.count)")
        print("  Total edges: \(edgesArray.count)")
        
        print("✅ JSON output test completed successfully!")
    }
    
    func testJSONOutputContainsExpectedEntities() async throws {
        // Arrange
        let configuration = Configuration()
        let project = try Project(configuration: configuration)
        let driver = try project.driver()
        try driver.build()
        
        let graph = SourceGraph(configuration: configuration, logger: .init(quiet: true))
        _ = try Scan(configuration: configuration, sourceGraph: graph).perform(project: project)
        
        let sourceGraphRepository = SourceGraphRepository(sourceGraph: graph)
        let graphOutputService = GraphOutputService()
        
        let edges = try await sourceGraphRepository.extractEdges()
        
        // Переходим во временную директорию для создания JSON
        FileManager.default.changeCurrentDirectoryPath(tempDirectory.path)
        
        // Act
        try await graphOutputService.buildGraph(edges: edges, format: .json)
        
        // Assert
        let jsonURL = tempDirectory.appendingPathComponent("Graph.json")
        let jsonData = try Data(contentsOf: jsonURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
        
        guard let nodes = jsonObject?["nodes"] as? [[String: Any]] else {
            XCTFail("Nodes should be an array of dictionaries")
            return
        }
        
        // Проверяем, что есть ожидаемые сущности
        let nodeIds = nodes.compactMap { $0["id"] as? String }
        let nodeEntityNames = nodes.compactMap { $0["entityName"] as? String }
        
        // Ищем User и UserManager в entityName или id
        let hasUser = nodeEntityNames.contains { $0.contains("User") } || 
                      nodeIds.contains { $0.contains("User") }
        let hasUserManager = nodeEntityNames.contains { $0.contains("UserManager") } || 
                            nodeIds.contains { $0.contains("UserManager") }
        
        print("\n🔍 Checking for expected entities:")
        print("  Found 'User': \(hasUser)")
        print("  Found 'UserManager': \(hasUserManager)")
        print("  All entity names: \(nodeEntityNames.joined(separator: ", "))")
        
        XCTAssertTrue(hasUser || hasUserManager, 
                     "JSON should contain User or UserManager entities")
        
        print("✅ JSON entities test completed successfully!")
    }
    
    func testJSONOutputIsValidJSON() async throws {
        // Arrange
        let configuration = Configuration()
        let project = try Project(configuration: configuration)
        let driver = try project.driver()
        try driver.build()
        
        let graph = SourceGraph(configuration: configuration, logger: .init(quiet: true))
        _ = try Scan(configuration: configuration, sourceGraph: graph).perform(project: project)
        
        let sourceGraphRepository = SourceGraphRepository(sourceGraph: graph)
        let graphOutputService = GraphOutputService()
        
        let edges = try await sourceGraphRepository.extractEdges()
        
        // Переходим во временную директорию для создания JSON
        FileManager.default.changeCurrentDirectoryPath(tempDirectory.path)
        
        // Act
        try await graphOutputService.buildGraph(edges: edges, format: .json)
        
        // Assert
        let jsonURL = tempDirectory.appendingPathComponent("Graph.json")
        let jsonData = try Data(contentsOf: jsonURL)
        
        // Проверяем, что JSON валиден и может быть распарсен
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
        
        XCTAssertNotNil(jsonObject, "JSON should be valid and parseable")
        
        // Проверяем, что JSON может быть сериализован обратно
        let reSerializedData = try JSONSerialization.data(
            withJSONObject: jsonObject,
            options: [.prettyPrinted, .sortedKeys]
        )
        
        XCTAssertGreaterThan(reSerializedData.count, 0, "Re-serialized JSON should not be empty")
        
        // Проверяем, что JSON содержит правильную структуру верхнего уровня
        guard let jsonDict = jsonObject as? [String: Any] else {
            XCTFail("JSON root should be a dictionary")
            return
        }
        
        XCTAssertTrue(jsonDict.keys.contains("nodes"), "JSON should have 'nodes' key")
        XCTAssertTrue(jsonDict.keys.contains("edges"), "JSON should have 'edges' key")
        
        print("✅ JSON validity test completed successfully!")
    }
}

