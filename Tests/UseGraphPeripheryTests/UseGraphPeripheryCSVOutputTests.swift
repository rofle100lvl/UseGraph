import XCTest
import Foundation
import SourceGraph
import Configuration
import ProjectDrivers
import Scan
import Shared
import UseGraphCore
@testable import UseGraphPeriphery

final class UseGraphPeripheryCSVOutputTests: XCTestCase {
    
    var testProjectPath: String!
    var originalWorkingDirectory: String!
    var tempDirectory: URL!
    
    override func setUp() {
        super.setUp()
        originalWorkingDirectory = FileManager.default.currentDirectoryPath
        
        // Создаем временную директорию для CSV файлов
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
    
    func testCSVOutputContainsNodes() async throws {
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
        
        // Переходим во временную директорию для создания CSV
        FileManager.default.changeCurrentDirectoryPath(tempDirectory.path)
        
        // Act
        try await graphOutputService.buildGraph(edges: edges, format: .csv)
        
        // Assert
        let nodesURL = tempDirectory.appendingPathComponent("Nodes.csv")
        let edgesURL = tempDirectory.appendingPathComponent("Edges.csv")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: nodesURL.path), "Nodes.csv should be created")
        XCTAssertTrue(FileManager.default.fileExists(atPath: edgesURL.path), "Edges.csv should be created")
        
        // Читаем содержимое Nodes.csv
        let nodesContent = try String(contentsOf: nodesURL, encoding: .utf8)
        print("\n📄 Nodes.csv content:")
        print(nodesContent)
        
        // Проверяем, что есть заголовки
        XCTAssertTrue(nodesContent.contains("id,moduleName,fileName,line,entityName,entityType"), 
                     "Nodes.csv should have correct headers")
        
        // Проверяем, что есть User и UserManager
        XCTAssertTrue(nodesContent.contains("User"), "Nodes.csv should contain User")
        XCTAssertTrue(nodesContent.contains("UserManager"), "Nodes.csv should contain UserManager")
        
        print("✅ CSV output test completed successfully!")
    }
    
    func testExtensionInfoAvailableInEdges() async throws {
        // Arrange
        let configuration = Configuration()
        let project = try Project(configuration: configuration)
        let driver = try project.driver()
        try driver.build()
        
        let graph = SourceGraph(configuration: configuration, logger: .init(quiet: true))
        _ = try Scan(configuration: configuration, sourceGraph: graph).perform(project: project)
        
        let sourceGraphRepository = SourceGraphRepository(sourceGraph: graph)
        let edges = try await sourceGraphRepository.extractEdges()
        
        // Act & Assert
        print("\n📊 Checking extensionInfo availability in edges")
        
        var totalReferences = 0
        var referencesWithExtension = 0
        
        for edge in edges {
            for ref in edge.references {
                totalReferences += 1
                if ref.extensionInfo != nil {
                    referencesWithExtension += 1
                    print("  ✓ Reference at line \(ref.line) has extensionInfo: \(ref.extensionInfo!)")
                }
            }
        }
        
        print("\n📈 Statistics:")
        print("  Total references: \(totalReferences)")
        print("  References with extensionInfo: \(referencesWithExtension)")
        print("  Percentage: \(referencesWithExtension * 100 / max(totalReferences, 1))%")
        
        XCTAssertGreaterThan(referencesWithExtension, 0, 
                            "Should have at least some references with extensionInfo")
        
        // TODO: В будущем нужно добавить вывод references в CSV
        // чтобы extensionInfo была доступна для анализа
        print("\n💡 Note: extensionInfo is available in Edge.references but not yet exported to CSV")
        print("   Consider adding References.csv with columns: edge_id, line, file, extensionInfo")
        
        print("✅ Extension info availability test completed!")
    }
}