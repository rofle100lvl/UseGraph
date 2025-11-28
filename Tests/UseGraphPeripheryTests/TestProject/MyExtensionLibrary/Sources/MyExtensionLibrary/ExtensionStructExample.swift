import Foundation

// Базовая структура
public struct User {
    public let name: String
    public let age: Int
    
    public init(name: String, age: Int) {
        self.name = name
        self.age = age
    }
}

// Extension добавляет методы к структуре
public extension User {
    func displayInfo() -> String {
        return "User: \(name), Age: \(age)"
    }
    
    func isAdult() -> Bool {
        return age >= 18
    }
}

// Класс, который использует методы из extension
public class UserManager {
    public init() {}
    
    public func processUser(_ user: User) -> String {
        let info = user.displayInfo()
        let status = user.isAdult() ? "Adult" : "Minor"
        let ageInfo = user.getFormattedAge() // Метод из отдельного extension файла
        return "\(info) - Status: \(status) - \(ageInfo)"
    }
    
    public func createDefaultUser() -> User {
        return User.createDefault() // Статический метод из extension
    }
}