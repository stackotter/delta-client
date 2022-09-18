import Foundation
#if !os(Linux)
import ZippyJSON
#endif

public struct CustomJSONDecoder {
  #if !os(Linux)
  public var keyDecodingStrategy: ZippyJSONDecoder.KeyDecodingStrategy
  #else
  public var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy
  #endif

  public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    #if !os(Linux)
    let decoder = ZippyJSONDecoder()
    #else
    let decoder = JSONDecoder()
    #endif
    decoder.keyDecodingStrategy = self.keyDecodingStrategy
    return try decoder.decode(type, from: data)
  }
}