import Foundation

public final class FileSystemService: FileSystemServiceProtocol {
    public init() {}
    
    public func findSubdirectories(atPath path: String) -> [String] {
        let fileManager = FileManager.default
        var subdirectories: [String] = []

        do {
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            for item in contents {
                let fullPath = (path as NSString).appendingPathComponent(item)
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory), isDirectory.boolValue {
                    subdirectories.append(fullPath)
                }
            }
        } catch {
            print("Error while reading the document: \(error)")
        }

        return subdirectories
    }
}