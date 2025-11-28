import Foundation

extension String {
    func matches(_ regex: String) -> Bool {
        return range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
}