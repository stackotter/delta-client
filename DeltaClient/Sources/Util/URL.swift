//
//  URL.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 24/4/21.
//

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
        Logger.warn("failed to append query items to url: \(self.absoluteString)")
        return self
      }
    }
    Logger.warn("failed to append query items to url: \(self.absoluteString)")
    return self
  }
}
