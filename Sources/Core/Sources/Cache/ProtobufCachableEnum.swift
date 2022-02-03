import Foundation
import SwiftProtobuf

/// Used to convert an enum to a Protobuf enum.
public protocol ProtobufCachableEnum {
  associatedtype Enum: SwiftProtobuf.Enum
  
  /// Creates an enum from a Protobuf enum.
  /// - Parameter protobufEnum: Protobuf enum to convert.
  init(from protobufEnum: Enum) throws
  
  /// Converts this enum to a Protobuf enum.
  /// - Returns: Resulting Protobuf enum.
  func cached() -> Enum
}
