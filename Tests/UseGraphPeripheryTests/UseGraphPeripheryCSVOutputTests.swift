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
        
        print("✅ Extension info availability test completed!")
    }
    
    func testCSVReferencesLinkedToEdgesByID() async throws {
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
        
        print("\n🧪 Testing CSV references are linked to edges via edge_id")
        
        // Act - Build CSV
        try await graphOutputService.buildGraph(edges: edges, format: .csv)
        
        // Assert - Check Edges.csv has IDs
        let edgesURL = tempDirectory.appendingPathComponent("Edges.csv")
        let edgesContent = try String(contentsOf: edgesURL, encoding: .utf8)
        let edgesLines = edgesContent.split(separator: "\n").map(String.init)
        
        XCTAssertGreaterThan(edgesLines.count, 1, "Edges.csv should have header and at least one edge")
        
        let edgesHeader = edgesLines[0]
        XCTAssertTrue(edgesHeader.hasPrefix("id,"), "Edges.csv should start with 'id,' column")
        print("✅ Edges.csv header: \(edgesHeader)")
        
        // Check first edge has ID = 1
        let firstEdge = edgesLines[1]
        let edgeComponents = firstEdge.split(separator: ",")
        XCTAssertEqual(String(edgeComponents[0]), "1", "First edge should have ID = 1")
        print("✅ First edge ID: \(edgeComponents[0])")
        
        // Assert - Check References.csv has edge_id
        let referencesURL = tempDirectory.appendingPathComponent("References.csv")
        let referencesContent = try String(contentsOf: referencesURL, encoding: .utf8)
        let referencesLines = referencesContent.split(separator: "\n").map(String.init)
        
        XCTAssertGreaterThan(referencesLines.count, 1, "References.csv should have header and at least one reference")
        
        let referencesHeader = referencesLines[0]
        XCTAssertTrue(referencesHeader.hasPrefix("edge_id,"), "References.csv should start with 'edge_id,' column")
        print("✅ References.csv header: \(referencesHeader)")
        
        // Count references per edge_id
        var referencesPerEdge: [String: Int] = [:]
        var referencesWithExtensionInfo = 0
        
        for line in referencesLines.dropFirst() {
            let components = line.split(separator: ",").map(String.init)
            XCTAssertGreaterThanOrEqual(components.count, 3, "Reference should have at least edge_id, line, file")
            
            let edgeId = components[0]
            XCTAssertFalse(edgeId.isEmpty, "Reference should have non-empty edge_id")
            referencesPerEdge[edgeId, default: 0] += 1
            
            // Check extensionInfo (last column) - file paths may contain commas
            let lastComponent = components.last ?? ""
            if !lastComponent.isEmpty && lastComponent.contains("extension:") {
                referencesWithExtensionInfo += 1
            }
        }
        
        print("📊 References per edge:")
        for (edgeId, count) in referencesPerEdge.sorted(by: { $0.key < $1.key }) {
            print("  Edge \(edgeId): \(count) references")
        }
        
        // Based on MyExtensionLibrary: 1 edge with 7 references, 4 with extensionInfo
        XCTAssertEqual(referencesPerEdge["1"], 7, "Edge 1 should have exactly 7 references")
        XCTAssertEqual(referencesWithExtensionInfo, 4, "Should have exactly 4 references with extensionInfo")
        
        print("✅ CSV files are properly linked via edge_id!")
        print("✅ Can now JOIN Edges.csv and References.csv by edge_id column")
    }
}