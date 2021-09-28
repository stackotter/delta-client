import Foundation

struct Request {
  var url: URL
  var body: Data?
  var method = RequestMethod.get
  var contentType = ContentType.text
  var headers: [String: String] = [:]
  
  init(_ url: URL) {
    self.url = url
  }
}
