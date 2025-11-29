import XCTest
import Foundation
import SourceGraph
import Configuration
import ProjectDrivers
import Scan
import Shared
import UseGraphCore
@testable import UseGraphPeriphery

final class UseGraphPeripheryProtocolExtensionTests: XCTestCase {
    
    var testProjectPath: String!
    var originalWorkingDirectory: String!
    
    override func setUp() {
        super.setUp()
        originalWorkingDirectory = FileManager.default.currentDirectoryPath
        
        let currentFile = #file
        let testDir = URL(fileURLWithPath: currentFile)
            .deletingLastPathComponent()
            .appendingPathComponent("TestProject")
            .appendingPathComponent("MyProtocolLibrary")
        testProjectPath = testDir.path
        
        FileManager.default.changeCurrentDirectoryPath(testProjectPath)
    }
    
    override func tearDown() {
        FileManager.default.changeCurrentDirectoryPath(originalWorkingDirectory)
        super.tearDown()
    }
    
    func testProtocolExtensionAndComputedProperties() async throws {
        // Arrange
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
        
        // Act
        let edges = try await sourceGraphRepository.extractEdges()
        
        // Assert
        print("📊 Extracted \(edges.count) edges from Protocol Extension test")
        
        let allNodes = Set(edges.flatMap { [$0.from, $0.to] })
        print("📋 Found \(allNodes.count) unique entities")
        
        // Ищем Product struct
        let productNodes = allNodes.filter { $0.entityName == "Product" && $0.entityType == "struct" }
        XCTAssertEqual(productNodes.count, 1, "Should find exactly 1 Product struct")
        
        // Ищем Describable protocol
        let describableNodes = allNodes.filter { $0.entityName == "Describable" && $0.entityType == "protocol" }
        XCTAssertGreaterThanOrEqual(describableNodes.count, 1, "Should find at least 1 Describable protocol")
        
        // Ищем ProductManager class
        let managerNodes = allNodes.filter { $0.entityName == "ProductManager" && $0.entityType == "class" }
        XCTAssertEqual(managerNodes.count, 1, "Should find exactly 1 ProductManager class")
        
        print("📋 All found entities:")
        for node in allNodes.sorted(by: { $0.entityName ?? "" < $1.entityName ?? "" }) {
            print("  - \(node.entityName ?? "Unknown") (\(node.entityType ?? "unknown")) at line \(node.line ?? "?") in \(node.moduleName)")
        }
        
        // Ищем edges с использованием extension методов/свойств
        let managerToProductEdges = edges.filter { edge in
            edge.from.entityName == "ProductManager" && edge.to.entityName == "Product"
        }
        
        let managerToDescribableEdges = edges.filter { edge in
            edge.from.entityName == "ProductManager" && edge.to.entityName == "Describable"
        }
        
        print("\n🔗 Found \(managerToProductEdges.count) edges from ProductManager to Product")
        print("🔗 Found \(managerToDescribableEdges.count) edges from ProductManager to Describable")
        
        // Используем helper для сбора references с extensionInfo
        let allReferencesWithExtension = ExtensionTestHelpers.collectReferencesWithExtension(from: edges)
        
        // Выводим детальную информацию
        ExtensionTestHelpers.printExtensionReferences(allReferencesWithExtension)
        
        // Проверяем, что есть references с extensionInfo для:
        // 1. Protocol extension (fullDescription, printDescription)
        // 2. Struct extension (priceDescription, isExpensive)
        
        let protocolExtensionRefs = allReferencesWithExtension.filter { 
            $0.ref.extensionInfo?.contains("Describable") ?? false 
        }
        let structExtensionRefs = allReferencesWithExtension.filter { 
            $0.ref.extensionInfo?.contains("Product") ?? false 
        }
        
        print("\n✅ Protocol extension references: \(protocolExtensionRefs.count)")
        print("✅ Struct extension references: \(structExtensionRefs.count)")
        
        XCTAssertGreaterThanOrEqual(protocolExtensionRefs.count, 1,
                                   "Should have at least 1 reference to protocol extension member")
        XCTAssertGreaterThanOrEqual(structExtensionRefs.count, 2,
                                   "Should have at least 2 references to struct extension members (computed properties)")
        
        // Проверяем extensionInfo используя helper
        for (edge, ref) in allReferencesWithExtension {
            guard let extInfo = ref.extensionInfo else { continue }
            
            if let parsed = ExtensionTestHelpers.validateExtensionInfo(extInfo, edge: edge) {
                // Проверяем конкретные значения для известных extensions
                if parsed.extendedType == "Product" {
                    ExtensionTestHelpers.assertExtensionInfo(extInfo,
                                                            extendedType: "Product",
                                                            extensionKind: "extension.struct",
                                                            extensionLine: "31")
                } else if parsed.extendedType == "Describable" {
                    ExtensionTestHelpers.assertExtensionInfo(extInfo,
                                                            extendedType: "Describable",
                                                            extensionKind: "extension.protocol",
                                                            extensionLine: "9")
                }
            }
        }
        
        print("\n🎉 Protocol extension and computed properties test completed successfully!")
    }
}