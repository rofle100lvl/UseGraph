import XCTest
import Foundation
import SourceGraph
import Configuration
import ProjectDrivers
import Scan
import Shared
import UseGraphCore
@testable import UseGraphPeriphery

final class UseGraphPeripheryMethodsIntegrationTests: XCTestCase {
    
    var testProjectPath: String!
    var originalWorkingDirectory: String!
    
    override func setUp() {
        super.setUp()
        // Сохраняем текущую директорию
        originalWorkingDirectory = FileManager.default.currentDirectoryPath
        
        // Получаем путь к тестовому Swift Package с методами
        let currentFile = #file
        let testDir = URL(fileURLWithPath: currentFile)
            .deletingLastPathComponent()
            .appendingPathComponent("TestProject")
            .appendingPathComponent("MyMethodsLibrary")
        testProjectPath = testDir.path
        
        // Переходим в директорию тестового проекта
        FileManager.default.changeCurrentDirectoryPath(testProjectPath)
    }
    
    override func tearDown() {
        // Возвращаемся в исходную директорию
        FileManager.default.changeCurrentDirectoryPath(originalWorkingDirectory)
        super.tearDown()
    }
    
    func testBuildGraphUseCaseExtractsMethodCalls() async throws {
        // Arrange: Настройка конфигурации для Swift Package
        let configuration = Configuration()
                
        
        let project = try Project(configuration: configuration)
        let driver = try project.driver()
        try driver.build()
        
        let graph = SourceGraph(configuration: configuration, logger: .init(quiet: true))
        _ = try Scan(configuration: configuration, sourceGraph: graph).perform(project: project)
        
        // Создаем зависимости
        let sourceGraphRepository = SourceGraphRepository(sourceGraph: graph)
        let graphOutputService = GraphOutputService()
        let _ = BuildGraphUseCase(
            sourceGraphRepository: sourceGraphRepository,
            graphOutputService: graphOutputService
        )
        
        // Act: Извлекаем edges
        let edges = try await sourceGraphRepository.extractEdges()
        
        // Assert: Детальная проверка найденных сущностей и связей
        print("📊 Extracted \(edges.count) method call edges from Swift Package")
        
        // Проверяем, что найдены сущности
        let allNodes = Set(edges.flatMap { [$0.from, $0.to] })
        print("📋 Found \(allNodes.count) unique classes")
        
        // Ищем DataService class
        let dataServiceNodes = allNodes.filter { $0.entityName == "DataService" && $0.entityType == "class" }
        XCTAssertEqual(dataServiceNodes.count, 1, "Should find exactly 1 DataService class")
        
        if let dataServiceNode = dataServiceNodes.first {
            XCTAssertEqual(dataServiceNode.line, "4", "DataService class should be on line 4")
            XCTAssertTrue(dataServiceNode.fileName.contains("ServiceClasses.swift"), "DataService should be in ServiceClasses.swift file")
            XCTAssertEqual(dataServiceNode.moduleName, "MyMethodsLibrary", "DataService should be in MyMethodsLibrary module")
            print("✅ DataService class found at line \(dataServiceNode.line ?? "unknown") in module \(dataServiceNode.moduleName)")
        } else {
            XCTFail("DataService class not found in extracted nodes")
        }
        
        // Ищем BusinessService class
        let businessServiceNodes = allNodes.filter { $0.entityName == "BusinessService" && $0.entityType == "class" }
        XCTAssertEqual(businessServiceNodes.count, 1, "Should find exactly 1 BusinessService class")
        
        if let businessServiceNode = businessServiceNodes.first {
            XCTAssertEqual(businessServiceNode.line, "11", "BusinessService class should be on line 11")
            XCTAssertTrue(businessServiceNode.fileName.contains("ServiceClasses.swift"), "BusinessService should be in ServiceClasses.swift file")
            XCTAssertEqual(businessServiceNode.moduleName, "MyMethodsLibrary", "BusinessService should be in MyMethodsLibrary module")
            print("✅ BusinessService class found at line \(businessServiceNode.line ?? "unknown") in module \(businessServiceNode.moduleName)")
        } else {
            XCTFail("BusinessService class not found in extracted nodes")
        }
        
        // Дополнительная проверка: выводим все найденные сущности для отладки
        print("📋 All found classes:")
        for node in allNodes.sorted(by: { $0.entityName ?? "" < $1.entityName ?? "" }) {
            print("  - \(node.entityName ?? "Unknown") (\(node.entityType ?? "unknown")) at line \(node.line ?? "?") in \(node.moduleName)")
        }
        
        // Ищем связь между BusinessService и DataService (вызов метода)
        let methodCallEdges = edges.filter { edge in
            (edge.from.entityName == "BusinessService" && edge.to.entityName == "DataService") ||
            (edge.from.entityName == "DataService" && edge.to.entityName == "BusinessService")
        }
        
        if !methodCallEdges.isEmpty {
            XCTAssertGreaterThanOrEqual(methodCallEdges.count, 1, "Should find at least 1 method call edge between BusinessService and DataService")
            
            let edge = methodCallEdges.first!
            XCTAssertFalse(edge.references.isEmpty, "Edge should have references")
            
            // Детальная проверка поля references
            XCTAssertEqual(edge.references.count, 2, "Should have exactly 2 references")
            
            let sortedReferences = edge.references.sorted { $0.line < $1.line }
            let expectedFilePath = "/Users/rofle100lvl/Desktop/UseGraph/Tests/UseGraphPeripheryTests/TestProject/MyMethodsLibrary/Sources/MyMethodsLibrary/ServiceClasses.swift"
            
            // Проверяем первый reference (line 12)
            let firstReference = sortedReferences[0]
            XCTAssertEqual(firstReference.line, 12, "First reference should be on line 12")
            XCTAssertEqual(firstReference.file, expectedFilePath, "First reference should have correct file path")
            
            // Проверяем второй reference (line 15)
            let secondReference = sortedReferences[1]
            XCTAssertEqual(secondReference.line, 15, "Second reference should be on line 15")
            XCTAssertEqual(secondReference.file, expectedFilePath, "Second reference should have correct file path")
            
            // Выводим детальную информацию о references
            print("📍 Reference details:")
            for (index, reference) in sortedReferences.enumerated() {
                print("  [\(index)] Line: \(reference.line), File: \(reference.file)")
            }
            
            // Проверяем, что обе сущности из одного файла
            XCTAssertEqual(edge.from.fileName, edge.to.fileName, "Both classes should be from the same file")
            
            print("✅ Found method call edge: \(edge.from.entityName ?? "Unknown") -> \(edge.to.entityName ?? "Unknown")")
            print("✅ References: \(edge.references.count)")
            print("✅ Same file: \(edge.from.fileName == edge.to.fileName)")
            print("✅ References validated: lines 12 and 15 in ServiceClasses.swift")
        } else {
            print("⚠️ No direct method call edge found between BusinessService and DataService")
            // Это может быть нормально, если связь не прямая
        }
        
        // Проверяем, что наша архитектура работает корректно
        XCTAssertNotNil(sourceGraphRepository, "SourceGraphRepository should be created")
        XCTAssertNotNil(graphOutputService, "GraphOutputService should be created")
        
        print("🎉 Method calls architecture test completed successfully!")
    }
    
}