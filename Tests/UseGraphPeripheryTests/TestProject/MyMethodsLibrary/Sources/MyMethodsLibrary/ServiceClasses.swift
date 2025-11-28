import Foundation

// Класс для работы с данными
class DataService {
    func fetchData() -> String {
        return "Data from DataService"
    }
}

// Класс для бизнес-логики, который использует DataService
class BusinessService {
    private let dataService = DataService()
    
    func performBusinessLogic() -> String {
        let data = dataService.fetchData()
        return "Business result: \(data)"
    }
}
