import Foundation
import SwiftProtobuf

/// Used to cache values to disk in the form of a Protobuf message.
public protocol ProtobufCachable {
  associatedtype Message: SwiftProtobuf.Message
  
  /// Loads a cached value from a Protobuf message.
  /// - Parameter message: Protobuf message containing a cached value.
  init(from message: Message) throws
  
  /// Caches this value into a Protobuf message.
  /// - Returns: Protobuf message containing a cache of this value.
  func cached() -> Message
}

extension ProtobufCachable {
  /// Loads a value from a Protobuf cache.
  /// - Parameter file: File containing Protobuf message.
  init(fromFile file: URL) throws {
    let data = try Data(contentsOf: file)
    let message = try Message(serializedData: data)
    try self.init(from: message)
  }
  
  /// Caches this value using Protobuf.
  /// - Parameter file: File to cache this value to.
  func cache(toFile file: URL) throws {
    let message = cached()
    let data = try message.serializedData()
    try data.write(to: file)
  }
}
