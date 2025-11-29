import XCTest
@testable import UseGraphPeriphery

enum ExtensionTestHelpers {
    
    /// Проверяет extensionInfo в reference и возвращает распарсенные компоненты
    static func validateExtensionInfo(
        _ extensionInfo: String,
        edge: UseGraphPeriphery.Edge,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (extendedType: String, extensionKind: String, extensionLine: String)? {
        
        // Проверяем формат
        XCTAssertTrue(extensionInfo.contains("extension:"), 
                     "Extension info should start with 'extension:'", 
                     file: file, line: line)
        
        // Парсим extensionInfo: "extension:<Type>:<Kind>:<Line>"
        let components = extensionInfo.split(separator: ":")
        XCTAssertEqual(components.count, 4, 
                      "Extension info should have 4 components: \(extensionInfo)", 
                      file: file, line: line)
        
        guard components.count == 4 else { return nil }
        
        let extendedType = String(components[1])
        let extensionKind = String(components[2])
        let extensionLine = String(components[3])
        
        // Проверяем, что extended type соответствует target в edge
        XCTAssertEqual(edge.to.entityName, extendedType, 
                      "Extended type '\(extendedType)' in extensionInfo should match edge target '\(edge.to.entityName ?? "nil")'",
                      file: file, line: line)
        
        // Проверяем, что extension kind корректный
        XCTAssertTrue(extensionKind.contains("extension"), 
                     "Extension kind '\(extensionKind)' should contain 'extension'",
                     file: file, line: line)
        
        return (extendedType, extensionKind, extensionLine)
    }
    
    /// Проверяет конкретные значения extensionInfo для известного типа
    static func assertExtensionInfo(
        _ extensionInfo: String,
        extendedType expectedType: String,
        extensionKind expectedKind: String,
        extensionLine expectedLine: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let components = extensionInfo.split(separator: ":")
        guard components.count == 4 else {
            XCTFail("Invalid extensionInfo format: \(extensionInfo)", file: file, line: line)
            return
        }
        
        let extendedType = String(components[1])
        let extensionKind = String(components[2])
        let extensionLine = String(components[3])
        
        XCTAssertEqual(extendedType, expectedType, 
                      "Extended type should be '\(expectedType)'", 
                      file: file, line: line)
        XCTAssertEqual(extensionKind, expectedKind, 
                      "Extension kind should be '\(expectedKind)'", 
                      file: file, line: line)
        XCTAssertEqual(extensionLine, expectedLine, 
                      "Extension line should be '\(expectedLine)'", 
                      file: file, line: line)
    }
    
    /// Собирает все references с extensionInfo из edges
    static func collectReferencesWithExtension(
        from edges: [UseGraphPeriphery.Edge]
    ) -> [(edge: UseGraphPeriphery.Edge, ref: UseGraphPeriphery.Reference)] {
        var result: [(edge: UseGraphPeriphery.Edge, ref: UseGraphPeriphery.Reference)] = []
        
        for edge in edges {
            for ref in edge.references {
                if ref.extensionInfo != nil {
                    result.append((edge, ref))
                }
            }
        }
        
        return result
    }
    
    /// Выводит детальную информацию о references с extensionInfo
    static func printExtensionReferences(
        _ references: [(edge: UseGraphPeriphery.Edge, ref: UseGraphPeriphery.Reference)]
    ) {
        print("\n📍 Found \(references.count) references with extensionInfo:")
        for (index, item) in references.enumerated() {
            print("  [\(index)] \(item.edge.from.entityName ?? "?") -> \(item.edge.to.entityName ?? "?")")
            print("       Line: \(item.ref.line), extensionInfo: \(item.ref.extensionInfo ?? "nil")")
            
            if let extInfo = item.ref.extensionInfo,
               let parsed = validateExtensionInfo(extInfo, edge: item.edge) {
                print("       Parsed: type=\(parsed.extendedType), kind=\(parsed.extensionKind), line=\(parsed.extensionLine)")
            }
        }
    }
}