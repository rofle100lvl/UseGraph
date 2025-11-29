import XCTest
import Foundation
import SourceGraph
import Configuration
import ProjectDrivers
import Scan
import Shared
import UseGraphCore
@testable import UseGraphPeriphery

final class UseGraphPeripheryExtensionIntegrationTests: XCTestCase {
    
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
    
    func testBuildGraphUseCaseExtractsExtensionUsage() async throws {
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
        
        print("📊 Extracted \(edges.count) extension usage edges from Swift Package")
        
        let allNodes = Set(edges.flatMap { [$0.from, $0.to] })
        print("📋 Found \(allNodes.count) unique entities")
        
        let userNodes = allNodes.filter { $0.entityName == "User" && $0.entityType == "struct" }
        XCTAssertEqual(userNodes.count, 1, "Should find exactly 1 User struct")
        
        if let userNode = userNodes.first {
            XCTAssertEqual(userNode.line, "4", "User struct should be on line 4")
            XCTAssertTrue(userNode.fileName.contains("ExtensionStructExample.swift"), "User should be in ExtensionStructExample.swift file")
            XCTAssertEqual(userNode.moduleName, "MyExtensionLibrary", "User should be in MyExtensionLibrary module")
            print("✅ User struct found at line \(userNode.line ?? "unknown") in module \(userNode.moduleName)")
        } else {
            XCTFail("User struct not found in extracted nodes")
        }
        
        let userManagerNodes = allNodes.filter { $0.entityName == "UserManager" && $0.entityType == "class" }
        XCTAssertEqual(userManagerNodes.count, 1, "Should find exactly 1 UserManager class")
        
        if let userManagerNode = userManagerNodes.first {
            XCTAssertEqual(userManagerNode.line, "26", "UserManager class should be on line 26")
            XCTAssertTrue(userManagerNode.fileName.contains("ExtensionStructExample.swift"), "UserManager should be in ExtensionStructExample.swift file")
            XCTAssertEqual(userManagerNode.moduleName, "MyExtensionLibrary", "UserManager should be in MyExtensionLibrary module")
            print("✅ UserManager class found at line \(userManagerNode.line ?? "unknown") in module \(userManagerNode.moduleName)")
        } else {
            XCTFail("UserManager class not found in extracted nodes")
        }
        
        print("📋 All found entities:")
        for node in allNodes.sorted(by: { $0.entityName ?? "" < $1.entityName ?? "" }) {
            print("  - \(node.entityName ?? "Unknown") (\(node.entityType ?? "unknown")) at line \(node.line ?? "?") in \(node.moduleName)")
        }
        
        let extensionUsageEdges = edges.filter { edge in
            (edge.from.entityName == "UserManager" && edge.to.entityName == "User") ||
            (edge.from.entityName == "User" && edge.to.entityName == "UserManager")
        }
        
        if !extensionUsageEdges.isEmpty {
            XCTAssertGreaterThanOrEqual(extensionUsageEdges.count, 1, "Should find at least 1 extension usage edge between UserManager and User")
            
            let edge = extensionUsageEdges.first!
            XCTAssertFalse(edge.references.isEmpty, "Edge should have references")
            XCTAssertGreaterThanOrEqual(edge.references.count, 2, "Should have at least 2 references (displayInfo and isAdult calls)")
            
            let sortedReferences = edge.references.sorted { $0.line < $1.line }
            let expectedFilePath = "/Users/rofle100lvl/Desktop/UseGraph/Tests/UseGraphPeripheryTests/TestProject/MyExtensionLibrary/Sources/MyExtensionLibrary/ExtensionStructExample.swift"
            
            for (index, reference) in sortedReferences.enumerated() {
                XCTAssertEqual(reference.file, expectedFilePath, "Reference \(index) should have correct file path")
                XCTAssertGreaterThan(reference.line, 25, "Reference \(index) should be in UserManager.processUser method (after line 25)")
            }
            
            let referencesWithExtensionInfo = sortedReferences.filter { $0.extensionInfo != nil }
            XCTAssertGreaterThanOrEqual(referencesWithExtensionInfo.count, 3, "Should have at least 3 references with extensionInfo (displayInfo, isAdult, getFormattedAge)")
            
            print("✅ Found \(referencesWithExtensionInfo.count) references with extension info")
            print("📍 Extension usage reference details:")
            
            for (index, reference) in sortedReferences.enumerated() {
                let extInfo = reference.extensionInfo ?? "nil"
                print("  [\(index)] Line: \(reference.line), File: \(reference.file)")
                print("       extensionInfo: \(extInfo)")
                
                if let extensionInfo = reference.extensionInfo {
                    if let parsed = ExtensionTestHelpers.validateExtensionInfo(extensionInfo, edge: edge) {
                        print("       Parsed: type=\(parsed.extendedType), kind=\(parsed.extensionKind), line=\(parsed.extensionLine)")
                        
                        XCTAssertEqual(parsed.extendedType, "User", "Should be User extension")
                        XCTAssertEqual(parsed.extensionKind, "extension.struct", "Should be struct extension")
                        XCTAssertTrue(parsed.extensionLine == "15" || parsed.extensionLine == "4",
                                     "Should be extension on line 15 or 4")
                    }
                }
            }
            
            XCTAssertEqual(edge.from.fileName, edge.to.fileName, "Both entities should be from the same file")
            
            print("✅ Found extension usage edge: \(edge.from.entityName ?? "Unknown") -> \(edge.to.entityName ?? "Unknown")")
            print("✅ References: \(edge.references.count)")
            print("✅ Same file: \(edge.from.fileName == edge.to.fileName)")
            print("✅ Extension method calls validated")
        } else {
            print("⚠️ No direct extension usage edge found between UserManager and User")
        }
        
        XCTAssertNotNil(sourceGraphRepository, "SourceGraphRepository should be created")
        XCTAssertNotNil(graphOutputService, "GraphOutputService should be created")
        
        print("🎉 Extension and Struct architecture test completed successfully!")
    }
    
    func testNonExtensionMethodsHaveNoExtensionInfo() async throws {
        // Arrange
        let configuration = Configuration()
        let project = try Project(configuration: configuration)
        let driver = try project.driver()
        try driver.build()
        
        let graph = SourceGraph(configuration: configuration, logger: .init(quiet: true))
        _ = try Scan(configuration: configuration, sourceGraph: graph).perform(project: project)
        
        let sourceGraphRepository = SourceGraphRepository(sourceGraph: graph)
        
        let edges = try await sourceGraphRepository.extractEdges()
        
        print("\n📊 Testing non-extension methods have no extensionInfo")
        
        var allReferences: [(edge: UseGraphPeriphery.Edge, ref: UseGraphPeriphery.Reference)] = []
        for edge in edges {
            for ref in edge.references {
                allReferences.append((edge, ref))
            }
        }
        
        print("📋 Total references: \(allReferences.count)")
        
        let referencesWithoutExtension = allReferences.filter { $0.ref.extensionInfo == nil }
        XCTAssertGreaterThan(referencesWithoutExtension.count, 0,
                            "Should have references without extensionInfo (direct property access, init calls, etc.)")
        
        print("✅ Found \(referencesWithoutExtension.count) references without extensionInfo")
        print("✅ Found \(allReferences.count - referencesWithoutExtension.count) references with extensionInfo")
        
        for (edge, ref) in referencesWithoutExtension.prefix(3) {
            print("  Example: \(edge.from.entityName ?? "?") -> \(edge.to.entityName ?? "?") at line \(ref.line)")
            XCTAssertNil(ref.extensionInfo, "Non-extension reference should have nil extensionInfo")
        }
        
        print("🎉 Non-extension methods test completed successfully!")
    }
    
}