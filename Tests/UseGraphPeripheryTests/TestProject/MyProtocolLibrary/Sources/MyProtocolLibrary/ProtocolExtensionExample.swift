import Foundation

// Базовый протокол
public protocol Describable {
    var name: String { get }
}

// Extension добавляет computed property и метод к протоколу
public extension Describable {
    var fullDescription: String {
        return "Description: \(name)"
    }
    
    func printDescription() {
        print(fullDescription)
    }
}

// Struct, который реализует протокол
public struct Product: Describable {
    public let name: String
    public let price: Double
    
    public init(name: String, price: Double) {
        self.name = name
        self.price = price
    }
}

// Extension для struct с computed property
public extension Product {
    var priceDescription: String {
        return "Price: $\(price)"
    }
    
    var isExpensive: Bool {
        return price > 100
    }
}

// Класс, который использует методы и свойства из extensions
public class ProductManager {
    public init() {}
    
    public func displayProduct(_ product: Product) -> String {
        let desc = product.fullDescription // Из protocol extension
        let price = product.priceDescription // Из struct extension
        let expensive = product.isExpensive ? "Expensive" : "Affordable" // Из struct extension
        return "\(desc), \(price), \(expensive)"
    }
    
    public func printProduct(_ product: Product) {
        product.printDescription() // Из protocol extension
    }
}