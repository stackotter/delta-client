import DeltaCore
import FirebladeMath

public struct ChunkUniforms {
  /// The translation to convert chunk-space coordinates (with origin at the
  /// lowest, Northmost, Eastmost block of the chunk) to world-space coordinates.
  public var transformation: Mat4x4f

  public init(transformation: Mat4x4f) {
    self.transformation = transformation
  }

  public init() {
    transformation = MatrixUtil.identity
  }
}
