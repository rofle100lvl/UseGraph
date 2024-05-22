//
//  File.swift
//  
//
//  Created by Roman Gorbenko on 21.05.2024.
//

import GraphViz

public enum OutputFormat {
    case svg
    case png
    case gv
    
    public static func parse(format: String) throws -> OutputFormat {
        switch format.lowercased() {
        case "svg":
                .svg
        case "png":
                .png
        case "gv":
                .gv
        default:
            throw FormatError.formatIsNotCorrect
        }
    }
    
    public func toFormat() -> Format {
        switch self {
        case .gv:
                .gv
        case .png:
                .png
        case .svg:
                .svg
        }
    }
}
