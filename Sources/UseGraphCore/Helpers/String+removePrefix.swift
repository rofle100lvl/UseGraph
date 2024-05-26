import Foundation

extension String {
  func removingPrefix(_ prefix: String) -> String {
    guard self.hasPrefix(prefix) else { return self }
    var urlString = String(self.dropFirst(prefix.count))
    if urlString.hasPrefix("/") {
      urlString = String(urlString.dropFirst())
    }
    return urlString
  }
}
