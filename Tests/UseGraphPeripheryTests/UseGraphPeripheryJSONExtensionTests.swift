import XCTest
import Foundation
import SourceGraph
import Configuration
import ProjectDrivers
import Scan
import Shared
import UseGraphCore
@testable import UseGraphPeriphery

final class UseGraphPeripheryJSONExtensionTests: XCTestCase {
    
    var testProjectPath: String!
    var originalWorkingDirectory: String!
    
    override func setUp() {
        super.setUp()
        originalWorkingDirectory = FileManager.default.currentDirectoryPath
        
        let currentFile = #file
        let testDir = URL(fileURLWithPath: currentFile)
            .deletingLastPathComponent()
            .appendingPathComponent("TestProject")
            .appendingPathComponent("MyExtensionLibrary")
        testProjectPath = testDir.path
        
        FileManager.default.changeCurrentDirectoryPath(testProjectPath)
    }
    
    override func tearDown() {
        FileManager.default.changeCurrentDirectoryPath(originalWorkingDirectory)
        super.tearDown()
    }
    
    func testJSONOutputIncludesExtensionInfo() async throws {
        // Arrange
        let configuration = Configuration()
        let project = try Project(configuration: configuration)
        let driver = try project.driver()
        try driver.build()
        
        let graph = SourceGraph(configuration: configuration, logger: .init(quiet: true))
        _ = try Scan(configuration: configuration, sourceGraph: graph).perform(project: project)
        
        let sourceGraphRepository = SourceGraphRepository(sourceGraph: graph)
        
        print("\n🧪 Testing JSON output includes extensionInfo")
        print("📂 Project path: \(testProjectPath!)")
        
        // Act
        let edges = try await sourceGraphRepository.extractEdges()
        
        print("📊 Found \(edges.count) edges")
        
        // Assert - Check that Edge has JSONRepresentable implementation
        XCTAssertGreaterThan(edges.count, 0, "Should have at least one edge")
        
        // Find edges with extension references
        let edgesWithExtensions = edges.filter { edge in
            edge.references.contains { $0.extensionInfo != nil }
        }
        
        XCTAssertGreaterThan(edgesWithExtensions.count, 0,
                            "Should have at least one edge with extension references")
        
        print("✅ Found \(edgesWithExtensions.count) edges with extension references")
        
        // Test JSON representation
        for edge in edgesWithExtensions.prefix(3) {
            let json = edge.jsonRepresentation
            
            // Verify structure
            XCTAssertNotNil(json["source"], "JSON should have 'source' field")
            XCTAssertNotNil(json["target"], "JSON should have 'target' field")
            XCTAssertNotNil(json["type"], "JSON should have 'type' field")
            XCTAssertNotNil(json["references"], "JSON should have 'references' field")
            
            // Verify references array
            guard let references = json["references"] as? [[String: Any]] else {
                XCTFail("References should be an array of dictionaries")
                continue
            }
            
            XCTAssertGreaterThan(references.count, 0, "Should have at least one reference")
            
            // Check that at least one reference has extensionInfo
            let referencesWithExtInfo = references.filter { ref in
                if let extInfo = ref["extensionInfo"] as? String {
                    return !extInfo.isEmpty
                }
                return false
            }
            
            XCTAssertGreaterThan(referencesWithExtInfo.count, 0,
                                "At least one reference should have extensionInfo")
            
            // Verify extensionInfo format
            for ref in referencesWithExtInfo {
                guard let extInfo = ref["extensionInfo"] as? String else { continue }
                
                XCTAssertTrue(extInfo.hasPrefix("extension:"),
                             "extensionInfo should start with 'extension:': \(extInfo)")
                
                let components = extInfo.split(separator: ":")
                XCTAssertEqual(components.count, 4,
                              "extensionInfo should have 4 components: \(extInfo)")
                
                print("  ✓ Valid extensionInfo: \(extInfo)")
            }
        }
        
        print("✅ All JSON representations include extensionInfo correctly")
    }
    
    func testJSONOutputStructure() async throws {
        // Arrange
        let configuration = Configuration()
        let project = try Project(configuration: configuration)
        let driver = try project.driver()
        try driver.build()
        
        let graph = SourceGraph(configuration: configuration, logger: .init(quiet: true))
        _ = try Scan(configuration: configuration, sourceGraph: graph).perform(project: project)
        
        let sourceGraphRepository = SourceGraphRepository(sourceGraph: graph)
        
        print("\n🧪 Testing complete JSON output structure")
        
        // Act
        let edges = try await sourceGraphRepository.extractEdges()
        
        // Test that we can serialize to JSON
        let edgesJSON = edges.map { $0.jsonRepresentation }
        
        let jsonData = try JSONSerialization.data(
            withJSONObject: ["edges": edgesJSON],
            options: [.prettyPrinted]
        )
        
        XCTAssertGreaterThan(jsonData.count, 0, "Should produce valid JSON data")
        
        // Verify we can deserialize it back
        let deserialized = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        XCTAssertNotNil(deserialized, "Should be able to deserialize JSON")
        
        guard let deserializedEdges = deserialized?["edges"] as? [[String: Any]] else {
            XCTFail("Should have edges array")
            return
        }
        
        XCTAssertEqual(deserializedEdges.count, edges.count,
                      "Deserialized edges count should match original")
        
        // Count references with extensionInfo
        var totalReferences = 0
        var referencesWithExtInfo = 0
        
        for edgeJSON in deserializedEdges {
            guard let references = edgeJSON["references"] as? [[String: Any]] else { continue }
            
            for ref in references {
                totalReferences += 1
                if let extInfo = ref["extensionInfo"] as? String, !extInfo.isEmpty {
                    referencesWithExtInfo += 1
                }
            }
        }
        
        print("📊 JSON Statistics:")
        print("  Total edges: \(deserializedEdges.count)")
        print("  Total references: \(totalReferences)")
        print("  References with extensionInfo: \(referencesWithExtInfo)")
        print("  Percentage: \(referencesWithExtInfo * 100 / max(totalReferences, 1))%")
        
        // Verify we have the expected extension method calls
        XCTAssertGreaterThanOrEqual(totalReferences, 4,
                                   "Should have at least 4 references (extension methods)")
        XCTAssertEqual(referencesWithExtInfo, 4,
                      "Should have exactly 4 references with extensionInfo:\n" +
                      "  - displayInfo(), isAdult(), getFormattedAge(), createDefault()")
        
        print("✅ JSON structure is valid and complete")
    }
}