import XCTest
import Foundation
import SourceGraph
import Configuration
import ProjectDrivers
import Scan
import Shared
import UseGraphCore
@testable import UseGraphPeriphery

final class UseGraphPeripheryIntegrationTests: XCTestCase {
    
    var testProjectPath: String!
    var originalWorkingDirectory: String!
    
    override func setUp() {
        super.setUp()
        originalWorkingDirectory = FileManager.default.currentDirectoryPath
        
        let currentFile = #file
        let testDir = URL(fileURLWithPath: currentFile)
            .deletingLastPathComponent()
            .appendingPathComponent("TestProject")
            .appendingPathComponent("MyLibrary")
        testProjectPath = testDir.path
        
        FileManager.default.changeCurrentDirectoryPath(testProjectPath)
    }
    
    override func tearDown() {
        FileManager.default.changeCurrentDirectoryPath(originalWorkingDirectory)
        super.tearDown()
    }
    
    func testBuildGraphUseCaseExtractsCorrectEdges() async throws {
        let configuration = Configuration()
        
        let project = try Project(configuration: configuration)
        let driver = try project.driver()
        try driver.build()
        
        let graph = SourceGraph(configuration: configuration, logger: .init(quiet: true))
        _ = try Scan(configuration: configuration, sourceGraph: graph).perform(project: project)
        
        let sourceGraphRepository = SourceGraphRepository(sourceGraph: graph)
        let graphOutputService = GraphOutputService()
        let _ = BuildGraphUseCase(
            sourceGraphRepository: sourceGraphRepository,
            graphOutputService: graphOutputService
        )
        
        let edges = try await sourceGraphRepository.extractEdges()
        
        print("📊 Extracted \(edges.count) edges from Swift Package")
        
        let allNodes = Set(edges.flatMap { [$0.from, $0.to] })
        print("📋 Found \(allNodes.count) unique nodes")
        
        let aNodes = allNodes.filter { $0.entityName == "A" && $0.entityType == "struct" }
        XCTAssertEqual(aNodes.count, 1, "Should find exactly 1 A struct")
        
        if let aNode = aNodes.first {
            XCTAssertEqual(aNode.line, "3", "A struct should be on line 3")
            XCTAssertTrue(aNode.fileName.contains("UserRepository.swift"), "A should be in UserRepository.swift file")
            XCTAssertEqual(aNode.moduleName, "MyLibrary", "A should be in MyLibrary module")
            print("✅ A struct found at line \(aNode.line ?? "unknown") in module \(aNode.moduleName)")
        } else {
            XCTFail("A struct not found in extracted nodes")
        }
        
        let bNodes = allNodes.filter { $0.entityName == "B" && $0.entityType == "class" }
        XCTAssertEqual(bNodes.count, 1, "Should find exactly 1 B class")
        
        if let bNode = bNodes.first {
            XCTAssertEqual(bNode.line, "9", "B class should be on line 9")
            XCTAssertTrue(bNode.fileName.contains("UserRepository.swift"), "B should be in UserRepository.swift file")
            XCTAssertEqual(bNode.moduleName, "MyLibrary", "B should be in MyLibrary module")
            print("✅ B class found at line \(bNode.line ?? "unknown") in module \(bNode.moduleName)")
        } else {
            XCTFail("B class not found in extracted nodes")
        }
        
        print("📋 All found entities:")
        for node in allNodes.sorted(by: { $0.entityName ?? "" < $1.entityName ?? "" }) {
            print("  - \(node.entityName ?? "Unknown") (\(node.entityType ?? "unknown")) at line \(node.line ?? "?") in \(node.moduleName)")
        }
        
        let bToAEdges = edges.filter { edge in
            (edge.from.entityName == "B" && edge.to.entityName == "A") ||
            (edge.from.entityName == "A" && edge.to.entityName == "B")
        }
        
        if !bToAEdges.isEmpty {
            XCTAssertEqual(bToAEdges.count, 1, "Should find exactly 1 edge between A and B")
            
            let edge = bToAEdges.first!
            XCTAssertFalse(edge.references.isEmpty, "Edge should have references")
            XCTAssertEqual(edge.from.fileName, edge.to.fileName, "Both entities should be from the same file")
            
            print("✅ Found edge: \(edge.from.entityName ?? "Unknown") -> \(edge.to.entityName ?? "Unknown")")
            print("✅ References: \(edge.references.count)")
            print("✅ Same file: \(edge.from.fileName == edge.to.fileName)")
        } else {
            print("⚠️ No direct edge found between A and B")
        }
        
        XCTAssertNotNil(sourceGraphRepository, "SourceGraphRepository should be created")
        XCTAssertNotNil(graphOutputService, "GraphOutputService should be created")
        
        print("🎉 Architecture test completed successfully!")
    }
    
    func testCSVOutputContainsReferences() async throws {
        // Arrange
        let configuration = Configuration()
        let project = try Project(configuration: configuration)
        let driver = try project.driver()
        try driver.build()
        
        let graph = SourceGraph(configuration: configuration, logger: .init(quiet: true))
        _ = try Scan(configuration: configuration, sourceGraph: graph).perform(project: project)
        
        let sourceGraphRepository = SourceGraphRepository(sourceGraph: graph)
        let graphOutputService = GraphOutputService()
        let buildGraphUseCase = BuildGraphUseCase(
            sourceGraphRepository: sourceGraphRepository,
            graphOutputService: graphOutputService
        )
        
        // Act: Build CSV graph
        try await buildGraphUseCase.execute(format: .csv)
        
        // Assert: Check that References.csv was created
        let referencesUrl = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appending(path: "References.csv")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: referencesUrl.path()),
                     "References.csv should be created")
        
        // Read and validate References.csv content
        let referencesData = try Data(contentsOf: referencesUrl)
        let referencesContent = String(data: referencesData, encoding: .utf8)
        XCTAssertNotNil(referencesContent, "References.csv should have content")
        
        // Check CSV header
        let lines = referencesContent?.components(separatedBy: .newlines) ?? []
        XCTAssertTrue(lines.count > 1, "References.csv should have header and data")
        XCTAssertTrue(lines[0].contains("line"), "Header should contain 'line'")
        XCTAssertTrue(lines[0].contains("file"), "Header should contain 'file'")
        XCTAssertTrue(lines[0].contains("extensionInfo"), "Header should contain 'extensionInfo'")
        
        print("✅ References.csv created successfully")
        print("📋 CSV content preview:")
        print(lines.prefix(5).joined(separator: "\n"))
        
        // Cleanup
        try? FileManager.default.removeItem(at: referencesUrl)
        let nodesUrl = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appending(path: "Nodes.csv")
        let edgesUrl = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appending(path: "Edges.csv")
        try? FileManager.default.removeItem(at: nodesUrl)
        try? FileManager.default.removeItem(at: edgesUrl)
    }
    
}
