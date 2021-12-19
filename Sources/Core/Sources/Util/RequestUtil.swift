import Foundation

enum RequestError: LocalizedError {
  case failedToConvertBodyToData
}

enum RequestUtil {
  static func performFormRequest(
    url: URL,
    body: [String: String],
    method: RequestMethod,
    onCompletion completion: @escaping (HTTPURLResponse, Data) -> Void,
    onFailure failure: @escaping (Error?) -> Void
  ) {
    let payload = RequestUtil.encodeParameters(body)
    
    guard let body = payload.data(using: .utf8) else {
      failure(RequestError.failedToConvertBodyToData)
      return
    }
    
    var request = Request(url)
    request.method = method
    request.contentType = .form
    request.body = body
    
    performRequest(request, onCompletion: completion, onFailure: failure)
  }
  
  static func performJSONRequest<T: Encodable>(
    url: URL,
    body: T,
    method: RequestMethod,
    onCompletion completion: @escaping (HTTPURLResponse, Data) -> Void,
    onFailure failure: @escaping (Error?) -> Void
  ) {
    var request = Request(url)
    request.method = method
    request.contentType = .json
    
    do {
      request.body = try JSONEncoder().encode(body)
    } catch {
      failure(error)
    }
    
    performRequest(request, onCompletion: completion, onFailure: failure)
  }
  
  static func performRequest(
    _ request: Request,
    onCompletion completion: @escaping (HTTPURLResponse, Data) -> Void,
    onFailure failure: @escaping (Error?) -> Void)
  {
    var urlRequest = URLRequest(url: request.url)
    urlRequest.httpMethod = request.method.rawValue
    urlRequest.httpBody = request.body
    
    urlRequest.addValue(request.contentType.rawValue, forHTTPHeaderField: "Content-Type")
    for (key, value) in request.headers {
      urlRequest.addValue(value, forHTTPHeaderField: key)
    }
    
    let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
      if let error = error {
        failure(error)
      } else if let data = data {
        if let response = response as? HTTPURLResponse {
          completion(response, data)
        } else {
          failure(nil)
        }
      } else {
        failure(nil)
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
