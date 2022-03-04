import Foundation
import FirebladeECS

/// A component storing an entity's UUID. Not to be confused with ``EntityId``.
public class EntityUUID: Component {
  public var uuid: UUID
  
  public init(_ uuid: UUID) {
    self.uuid = uuid
  }
}
