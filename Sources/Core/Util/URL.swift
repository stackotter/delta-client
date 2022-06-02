import Foundation

extension URL {
  func appendingQueryItems(_ items: [String: String]) -> URL {
    if var components = URLComponents(url: self, resolvingAgainstBaseURL: true) {
      var queryItems = components.queryItems ?? []
      for (key, value) in items {
        queryItems.append(URLQueryItem(name: key, value: value))
      }
      components.queryItems = queryItems
      
      if let newURL = components.url {
        return newURL
      } else {
        log.warning("failed to append query items to url: \(self.absoluteString)")
        return self
      }
    }
    log.warning("failed to append query items to url: \(self.absoluteString)")
    return self
  }
}
