import Foundation

/// A component storing an object's UUID. Not to be confused with.
public struct ObjectUUID {
  public var uuid: UUID
  
  public init(_ uuid: UUID) {
    self.uuid = uuid
  }
}
