//
//  RequestUtil.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/4/21.
//

import Foundation

struct RequestUtil {
  static func get(_ url: URL, _ data: Data, completion: @escaping (Data?, Error?) -> Void) {
    RequestUtil.request(url, data, method: .get, completion: completion)
  }
  
  static func post(_ url: URL, _ data: Data, completion: @escaping (Data?, Error?) -> Void) {
    RequestUtil.request(url, data, method: .post, completion: completion)
  }
  
  static func request(_ url: URL, _ data: Data, method: RequestMethod, completion: @escaping (Data?, Error?) -> Void) {
    var request = URLRequest(url: url)
    request.httpBody = data
    request.httpMethod = method.rawValue
    request.allHTTPHeaderFields = [
      "Content-Type": "application/json"
    ]
    
    let task = URLSession.shared.dataTask(with: request) { data, _, error in
      completion(data, error)
    }
    task.resume()
  }
}
