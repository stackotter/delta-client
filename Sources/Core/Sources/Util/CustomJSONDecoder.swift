import Foundation
#if canImport(ZippyJSON)
import ZippyJSON
#endif

public struct CustomJSONDecoder {
  #if canImport(ZippyJSON)
  public var keyDecodingStrategy: ZippyJSONDecoder.KeyDecodingStrategy = ZippyJSONDecoder.KeyDecodingStrategy.useDefaultKeys
  #else
  public var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = JSONDecoder.KeyDecodingStrategy.useDefaultKeys
  #endif

  public init() {}

  public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    #if canImport(ZippyJSON)
    let decoder = ZippyJSONDecoder()
    #else
    let decoder = JSONDecoder()
    #endif
    decoder.keyDecodingStrategy = self.keyDecodingStrategy
    return try decoder.decode(type, from: data)
  }
}