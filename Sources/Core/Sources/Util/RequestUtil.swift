import Foundation

enum RequestError: LocalizedError {
  /// The request's body could not be converted to data.
  case failedToConvertBodyToData
  /// The response was not of type HTTP.
  case invalidURLResponse
  /// The status code of the response was not greater than or equal to 400.
  case unsuccessfulRequest(Int)
}

enum RequestUtil {
  static func performFormRequest(
    url: URL,
    body: [String: String],
    method: RequestMethod
  ) async throws -> (HTTPURLResponse, Data) {
    let payload = RequestUtil.encodeParameters(body)
    
    guard let body = payload.data(using: .utf8) else {
      throw RequestError.failedToConvertBodyToData
    }
    
    var request = Request(url)
    request.method = method
    request.contentType = .form
    request.body = body
    
    return try await performRequest(request)
  }
  
  static func performJSONRequest<T: Encodable>(
    url: URL,
    body: T,
    method: RequestMethod
  ) async throws -> (HTTPURLResponse, Data) {
    var request = Request(url)
    request.method = method
    request.contentType = .json
    
    request.body = try JSONEncoder().encode(body)
    
    return try await performRequest(request)
  }
  
  static func performRequest(_ request: Request) async throws -> (HTTPURLResponse, Data) {
    var urlRequest = URLRequest(url: request.url)
    urlRequest.httpMethod = request.method.rawValue
    urlRequest.httpBody = request.body
    
    urlRequest.addValue(request.contentType.rawValue, forHTTPHeaderField: "Content-Type")
    for (key, value) in request.headers {
      urlRequest.addValue(value, forHTTPHeaderField: key)
    }
    
    return try await withCheckedThrowingContinuation { continuation in
      let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
        if let error = error {
          continuation.resume(throwing: error)
          return
        }
        
        guard let httpResponse = response as? HTTPURLResponse, let data = data else {
          continuation.resume(throwing: RequestError.invalidURLResponse)
          return
        }
        
        if httpResponse.statusCode >= 400 {
          continuation.resume(throwing: RequestError.unsuccessfulRequest(httpResponse.statusCode))
          return
        }
        
        continuation.resume(returning: (httpResponse, data))
      }
      task.resume()
    }
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
