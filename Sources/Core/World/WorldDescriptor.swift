import Foundation

public protocol WorldDescriptor {
  var worldName: Identifier { get }
  var dimension: Identifier { get }
  var hashedSeed: Int { get }
  var isDebug: Bool { get }
  var isFlat: Bool { get }
}
