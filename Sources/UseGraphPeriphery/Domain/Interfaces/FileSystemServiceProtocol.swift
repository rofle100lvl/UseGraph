import Foundation

public protocol FileSystemServiceProtocol {
    func findSubdirectories(atPath path: String) -> [String]
}