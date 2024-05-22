import XCTest
import SwiftSyntax
import SwiftParser
@testable import UseGraphCore

final class OwnershipFinderClosureTests: XCTestCase {
    func testClassWithVariableInside() throws {
        let rootNode: SourceFileSyntax = Parser.parse(source: classWithVariableInside)
        let visitor = DefinitionVisitor(converter: SourceLocationConverter(fileName: "", tree: rootNode))
        visitor.walk(rootNode)
        XCTAssertEqual(visitor.possibleToOptimizeNames, ["A": Set(["SomeClass"])])
    }
    
    func testClassWithFunction() throws {
        let rootNode: SourceFileSyntax = Parser.parse(source: classWithFunction)
        let visitor = DefinitionVisitor(converter: SourceLocationConverter(fileName: "", tree: rootNode))
        visitor.walk(rootNode)
        XCTAssertEqual(visitor.possibleToOptimizeNames, ["A": Set(["SomeClass"])])
    }
    
    func testClassWithInnerStruct() throws {
        let rootNode: SourceFileSyntax = Parser.parse(source: classWithInnerStruct)
        let visitor = DefinitionVisitor(converter: SourceLocationConverter(fileName: "", tree: rootNode))
        visitor.walk(rootNode)
        XCTAssertEqual(visitor.possibleToOptimizeNames, ["B": Set(["SomeClass"]), "A": Set(["B"])])
    }
    
    func testTwoClassesWithConnectionBetweenThem() throws {
        let rootNode: SourceFileSyntax = Parser.parse(source: twoClassesWithConnectionBetweenThem)
        let visitor = DefinitionVisitor(converter: SourceLocationConverter(fileName: "", tree: rootNode))
        visitor.walk(rootNode)
        XCTAssertEqual(visitor.possibleToOptimizeNames, ["B": Set(["SomeClass"]), "A": Set(["B"])])
        print(GraphBuilder.shared.buildGraph(dependencyGraph: visitor.possibleToOptimizeNames))
        sleep(5)
        
    }
    
}

extension OwnershipFinderClosureTests {
    var classWithVariableInside: String {
"""
class A {
    let a: SomeClass = 5
}
"""
    }
    
    var classWithFunction: String {
"""
class A {
    func someFunc() -> SomeClass {
        SomeClass()
    }
}
"""
    }
    
    var classWithInnerStruct: String {
"""
class A {
    struct B {
        let someClass: SomeClass
    }
}
"""
    }
    
    var twoClassesWithConnectionBetweenThem: String {
"""
struct B {
    let someClass: SomeClass
}

class A {
    let b: B
}
"""
    }
    
}
