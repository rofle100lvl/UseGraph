import Foundation

struct A {
    let id: String
    let name: String
    let email: String
}

class B {
    private var items: [String: A] = [:]
}

/*
 ▿ 1 element
   ▿ 0 : Edge
     ▿ from : Node
       - moduleName : "MyLibrary"
       - fileName : "...UseGraph/Tests/UseGraphPeripheryTests/TestProject/MyLibrary/Sources/MyLibrary/UserRepository.swift"
       ▿ line : Optional<String>
         - some : "9"
       - containerName : nil
       ▿ entityName : Optional<String>
         - some : "B"
       ▿ entityType : Optional<String>
         - some : "class"
       ▿ usrs : 1 element
         - 0 : "s:9MyLibrary1BC"
     ▿ to : Node
       - moduleName : "MyLibrary"
       - fileName : "...UseGraph/Tests/UseGraphPeripheryTests/TestProject/MyLibrary/Sources/MyLibrary/UserRepository.swift"
       ▿ line : Optional<String>
         - some : "3"
       - containerName : nil
       ▿ entityName : Optional<String>
         - some : "A"
       ▿ entityType : Optional<String>
         - some : "struct"
       ▿ usrs : 1 element
         - 0 : "s:9MyLibrary1AV"
     ▿ references : 1 element
       ▿ 0 : Reference
         - line : 10
         - file : "...UseGraph/Tests/UseGraphPeripheryTests/TestProject/MyLibrary/Sources/MyLibrary/UserRepository.swift"
 */
