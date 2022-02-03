import Foundation
import FirebladeECS

/// A component storing an object's UUID. Not to be confused with.
public class ObjectUUID: Component {
  /// An object's UUID.
  public var uuid: UUID
  
  /// Creates an object UUID component.
  public init(_ uuid: UUID) {
    self.uuid = uuid
  }
}
