import Foundation

public protocol CSVBuilding {
  func createCSV(from recArray: [CSVRepresentable]) -> String
}

public final class CSVBuilder: CSVBuilding {
  public init() {}
  
  public func createCSV(from recArray: [CSVRepresentable]) -> String {
      guard let fields = recArray.first?.fields else { return "" }
      var csvString = fields.joined(separator: ",") + "\n"
      for dct in recArray {
          csvString = csvString.appending(dct.csvRepresentation + "\n")
      }
      return csvString
  }
}
