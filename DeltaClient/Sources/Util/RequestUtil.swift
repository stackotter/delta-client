//
//  RequestUtil.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/4/21.
//

import Foundation

enum RequestError: LocalizedError {
  case requestFailedWithNoError
  case failedToEncodeRequestBody
}

struct RequestUtil {
  static func perform(
    _ request: Request,
    onCompletion: @escaping (HTTPURLResponse, Data) -> Void,
    onFailure: @escaping (Error) -> Void)
  {
    var urlRequest = URLRequest(url: request.url)
    urlRequest.httpMethod = request.method.rawValue
    urlRequest.httpBody = request.body
    
    urlRequest.addValue(request.contentType.rawValue, forHTTPHeaderField: "Content-Type")
    for (key, value) in request.headers {
      urlRequest.addValue(value, forHTTPHeaderField: key)
    }
    
    let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
      if let response = response as? HTTPURLResponse {
        print(response)
      }
      if let error = error {
        onFailure(error)
      } else if let data = data {
        if let response = response as? HTTPURLResponse {
          onCompletion(response, data)
        }
      } else {
        onFailure(RequestError.requestFailedWithNoError)
      }
    }
    task.resume()
  }
  
  static func urlEncode(_ string: String) -> String {
    return string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
  }
  
  static func encodeParameters(_ parameters: [String: String]) -> String {
    let parameterArray = parameters.map { (key, value) -> String in
      return "\(urlEncode(key))=\(urlEncode(value))"
    }
    return parameterArray.joined(separator: "&")
  }
}
