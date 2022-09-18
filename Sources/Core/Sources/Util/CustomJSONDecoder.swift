import Foundation
#if !os(Linux)
import ZippyJSON
#endif

public struct CustomJSONDecoder {
  #if !os(Linux)
  public var keyDecodingStrategy: ZippyJSONDecoder.KeyDecodingStrategy = ZippyJSONDecoder.KeyDecodingStrategy.useDefaultKeys
  #else
  public var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = JSONDecoder.KeyDecodingStrategy.useDefaultKeys
  #endif

  public init() {
    // Empty initialiser because we do not want the keyDecodingStrategy to be an initialiser parameter
  }

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