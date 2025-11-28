import Foundation

public enum OutputFormat {
    case svg
    case png
    case gv
    case csv
    
    public static func parse(format: String) throws -> OutputFormat {
        switch format.lowercased() {
        case "svg":
            return .svg
        case "png":
            return .png
        case "gv":
            return .gv
        case "csv":
            return .csv
        default:
            throw OutputFormatError.formatIsNotCorrect
        }
    }
}

public enum OutputFormatError: Error {
    case formatIsNotCorrect
    
    public var localizedDescription: String {
        switch self {
        case .formatIsNotCorrect:
            return "Format is not correct. Available formats: CSV, SVG, PNG, GV"
        }
    }
}