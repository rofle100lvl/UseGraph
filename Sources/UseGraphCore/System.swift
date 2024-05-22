import Combine
import Foundation

class System {
    static let shared = System()
    
    private init() { }
    
    func run(_ cmd: String) -> String? {
        let pipe = Pipe()
        let process = Process()
        process.launchPath = "/bin/sh"
        process.arguments = ["-c", String(format:"%@", cmd)]
        process.standardOutput = pipe
        let fileHandle = pipe.fileHandleForReading
        process.launch()
        return String(data: fileHandle.readDataToEndOfFile(), encoding: .utf8)
    }
}
enum ProcessError: Error {
    case system(Error)
    case terminated(code: Int)
}
