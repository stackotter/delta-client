import Foundation

/// The vertex format used by the chunk block shader.
public struct BlockVertex {
  var x: Float
  var y: Float
  var z: Float
  var u: Float
  var v: Float
  var r: Float
  var g: Float
  var b: Float
  var a: Float
  var skyLightLevel: UInt8
  var blockLightLevel: UInt8
  var textureIndex: UInt16
  var isTransparent: Bool
}
