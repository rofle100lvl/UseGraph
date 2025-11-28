import Foundation

// Extension в отдельном файле
public extension User {
    func getFormattedAge() -> String {
        return "Age: \(age) years"
    }
    
    static func createDefault() -> User {
        return User(name: "Default User", age: 25)
    }
}