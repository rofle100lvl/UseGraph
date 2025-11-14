import GraphViz
import Utils

public enum OutputFormat {
    case svg
    case png
    case gv
    case csv
    case json

    public static func parse(format: String) throws -> OutputFormat {
        switch format.lowercased() {
        case "svg":
            .svg
        case "png":
            .png
        case "gv":
            .gv
        case "csv":
            .csv
        case "json":
            .json
        default:
            throw FormatError.formatIsNotCorrect
        }
    }
}
