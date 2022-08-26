import Foundation
import simd

/// The vertex format used by the chunk block shader.
public struct BlockVertex {
  let x: Float
  let y: Float
  let z: Float
  let u: Float
  let v: Float
  let r: Float
  let g: Float
  let b: Float
  let a: Float
  let textureIndex: UInt16
  let isTransparent: Bool
}
