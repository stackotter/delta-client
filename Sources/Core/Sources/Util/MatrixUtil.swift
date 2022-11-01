import Foundation
import FirebladeMath

public enum MatrixUtil {
  public static var identity = Mat4x4f(diagonal: 1)

  public static func translationMatrix(_ translation: Vec3f) -> Mat4x4f {
    var matrix = Mat4x4f(diagonal: 1)
    matrix[0, 3] = translation.x
    matrix[1, 3] = translation.y
    matrix[2, 3] = translation.z
    return matrix
  }

  public static func translationMatrix(_ translation: Vec3d) -> Mat4x4d {
    var matrix = Mat4x4d(diagonal: 1)
    matrix[0, 3] = translation.x
    matrix[1, 3] = translation.y
    matrix[2, 3] = translation.z
    return matrix
  }

  public static func scalingMatrix(_ factor: Float) -> Mat4x4f {
    return scalingMatrix(factor, factor, factor)
  }

  public static func scalingMatrix(_ factor: Double) -> Mat4x4d {
    return scalingMatrix(factor, factor, factor)
  }

  public static func scalingMatrix(_ x: Float, _ y: Float, _ z: Float) -> Mat4x4f {
    return scalingMatrix(Vec3f(x, y, z))
  }

  public static func scalingMatrix(_ x: Double, _ y: Double, _ z: Double) -> Mat4x4d {
    return scalingMatrix(Vec3d(x, y, z))
  }

  public static func scalingMatrix(_ vector: Vec3f) -> Mat4x4f {
    return Mat4x4f(diagonal: Vec4f(vector, 1))
  }

  public static func scalingMatrix(_ vector: Vec3d) -> Mat4x4d {
    return Mat4x4d(diagonal: Vec4d(vector, 1))
  }

  public static func projectionMatrix(near: Float, far: Float, aspect: Float, fieldOfViewY: Float) -> Mat4x4f {
    let scaleY = 1 / Foundation.tan(fieldOfViewY * 0.5)
    let scaleX = scaleY / aspect
    let scaleZ = -far / (far - near)
    let scaleW = -far * near / (far - near)
    return Mat4x4f([
      Vec4f([scaleX, 0, 0, 0]),
      Vec4f([0, scaleY, 0, 0]),
      Vec4f([0, 0, scaleZ, scaleW]),
      Vec4f([0, 0, -1, 0])
    ])
  }

  public static func projectionMatrix(near: Double, far: Double, aspect: Double, fieldOfViewY: Double) -> Mat4x4d {
    let scaleY = 1 / Foundation.tan(fieldOfViewY * 0.5)
    let scaleX = scaleY / aspect
    let scaleZ = -far / (far - near)
    let scaleW = -far * near / (far - near)
    return Mat4x4d([
      Vec4d([scaleX, 0, 0, 0]),
      Vec4d([0, scaleY, 0, 0]),
      Vec4d([0, 0, scaleZ, scaleW]),
      Vec4d([0, 0, -1, 0])
    ])
  }

  /// Returns the rotation matrix applying the rotations in the order of x, then y and then z.
  public static func rotationMatrix(_ rotation: Vec3f) -> Mat4x4f {
    let matrix = rotationMatrix(x: rotation.x)
      * rotationMatrix(y: rotation.y)
      * rotationMatrix(z: rotation.z)
    return matrix
  }

  /// Returns the rotation matrix applying the rotations in the order of x, then y and then z.
  public static func rotationMatrix(_ rotation: Vec3d) -> Mat4x4d {
    let matrix = rotationMatrix(x: rotation.x)
      * rotationMatrix(y: rotation.y)
      * rotationMatrix(z: rotation.z)
    return matrix
  }

  public static func rotationMatrix(_ radians: Float, around axis: Axis) -> Mat4x4f {
    switch axis {
      case .x:
        return rotationMatrix(x: radians)
      case .y:
        return rotationMatrix(y: radians)
      case .z:
        return rotationMatrix(z: radians)
    }
  }

  public static func rotationMatrix(_ radians: Double, around axis: Axis) -> Mat4x4d {
    switch axis {
      case .x:
        return rotationMatrix(x: radians)
      case .y:
        return rotationMatrix(y: radians)
      case .z:
        return rotationMatrix(z: radians)
    }
  }

  public static func rotationMatrix(x: Float) -> Mat4x4f {
    let matrix = Mat4x4f([
      Vec4f(1, 0, 0, 0),
      Vec4f(
        0,
        Foundation.cos(x),
        Foundation.sin(x),
        0
      ),
      Vec4f(
        0,
        -Foundation.sin(x),
        Foundation.cos(x),
        0
      ),
      Vec4f(0, 0, 0, 1)
    ])
    return matrix
  }

  public static func rotationMatrix(x: Double) -> Mat4x4d {
    let matrix = Mat4x4d([
      Vec4d(1, 0, 0, 0),
      Vec4d(
        0,
        Foundation.cos(x),
        Foundation.sin(x),
        0
      ),
      Vec4d(
        0,
        -Foundation.sin(x),
        Foundation.cos(x),
        0
      ),
      Vec4d(0, 0, 0, 1)
    ])
    return matrix
  }

  public static func rotationMatrix(y: Float) -> Mat4x4f {
    let matrix = Mat4x4f([
      Vec4f(
        Foundation.cos(y),
        0,
        -Foundation.sin(y),
        0
      ),
      Vec4f(0, 1, 0, 0),
      Vec4f(
        Foundation.sin(y),
        0,
        Foundation.cos(y),
        0
      ),
      Vec4f(0, 0, 0, 1)
    ])
    return matrix
  }

  public static func rotationMatrix(y: Double) -> Mat4x4d {
    let matrix = Mat4x4d([
      Vec4d(
        Foundation.cos(y),
        0,
        -Foundation.sin(y),
        0
      ),
      Vec4d(0, 1, 0, 0),
      Vec4d(
        Foundation.sin(y),
        0,
        Foundation.cos(y),
        0
      ),
      Vec4d(0, 0, 0, 1)
    ])
    return matrix
  }

  public static func rotationMatrix(z: Float) -> Mat4x4f {
    let matrix = Mat4x4f([
      Vec4f(
        Foundation.cos(z),
        -Foundation.sin(z),
        0,
        0
      ),
      Vec4f(
        Foundation.sin(z),
        Foundation.cos(z),
        0,
        0
      ),
      Vec4f(0, 0, 1, 0),
      Vec4f(0, 0, 0, 1)
    ])
    return matrix
  }

  public static func rotationMatrix(z: Double) -> Mat4x4d {
    let matrix = Mat4x4d([
      Vec4d(
        Foundation.cos(z),
        -Foundation.sin(z),
        0,
        0
      ),
      Vec4d(
        Foundation.sin(z),
        Foundation.cos(z),
        0,
        0
      ),
      Vec4d(0, 0, 1, 0),
      Vec4d(0, 0, 0, 1)
    ])
    return matrix
  }

  public static func rotationMatrix2d(_ angle: Float) -> Mat2x2f {
    return Mat2x2f(
      Vec2f(Foundation.cos(angle), -Foundation.sin(angle)),
      Vec2f(Foundation.sin(angle), Foundation.cos(angle))
    )
  }

  public static func rotationMatrix2d(_ angle: Double) -> Mat2x2d {
    return Mat2x2d(
      Vec2d(Foundation.cos(angle), -Foundation.sin(angle)),
      Vec2d(Foundation.sin(angle), Foundation.cos(angle))
    )
  }

  public static func matrix4x4to3x3(_ matrix: Mat4x4f) -> Mat3x3f {
    return Mat3x3f([
      Vec3f(
        matrix.columns.0.x,
        matrix.columns.0.y,
        matrix.columns.0.z
      ),
      Vec3f(
        matrix.columns.1.x,
        matrix.columns.1.y,
        matrix.columns.1.z
      ),
      Vec3f(
        matrix.columns.2.x,
        matrix.columns.2.y,
        matrix.columns.2.z
      )
    ])
  }

  public static func matrix4x4to3x3(_ matrix: Mat4x4d) -> Mat3x3d {
    return Mat3x3d([
      Vec3d(
        matrix.columns.0.x,
        matrix.columns.0.y,
        matrix.columns.0.z
      ),
      Vec3d(
        matrix.columns.1.x,
        matrix.columns.1.y,
        matrix.columns.1.z
      ),
      Vec3d(
        matrix.columns.2.x,
        matrix.columns.2.y,
        matrix.columns.2.z
      )
    ])
  }
}
