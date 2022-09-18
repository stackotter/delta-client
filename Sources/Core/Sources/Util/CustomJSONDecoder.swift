import Foundation
#if !os(Linux)
import ZippyJSON
#endif

public struct CustomJSONDecoder {
  public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    #if !os(Linux)
    let decoder = CustomJSONDecoder()
    #else
    let decoder = JSONDecoder()
    #endif
    return decoder.decode(type, from: data)
  }
}