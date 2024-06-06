import Foundation

public extension String {
    @inlinable
    var trimmed: String {
        return trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}
