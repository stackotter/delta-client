import FirebladeMath

/// A sequence of voxels along a ray.
///
/// Algorithm explanation: https://github.com/sketchpunk/FunWithWebGL2/blob/master/lesson_074_voxel_ray_intersection/test.html
public struct VoxelRay: Sequence, IteratorProtocol {
  public var count: Int

  private let step: Vec3i
  private let initialVoxel: Vec3i
  private let boundaryDistanceStep: Vec3f

  private var isFirst = true
  private var nextBoundaryDistance: Vec3f
  private var previousVoxel: Vec3i

  public init(along ray: Ray, count: Int? = nil) {
    self.init(from: ray.origin, direction: ray.direction, count: count)
  }

  public init(from position: Vec3f, direction: Vec3f, count: Int? = nil) {
    step = Vec3i(MathUtil.sign(direction))

    initialVoxel = Vec3i(
      Int(position.x.rounded(.down)),
      Int(position.y.rounded(.down)),
      Int(position.z.rounded(.down))
    )

    nextBoundaryDistance = Vec3f(
      (position.x.rounded(.down) + (step.x == -1 ? 0 : 1) - position.x) / direction.x,
      (position.y.rounded(.down) + (step.y == -1 ? 0 : 1) - position.y) / direction.y,
      (position.z.rounded(.down) + (step.z == -1 ? 0 : 1) - position.z) / direction.z
    )

    boundaryDistanceStep = Vec3f(
      Float(step.x) / direction.x,
      Float(step.y) / direction.y,
      Float(step.z) / direction.z
    )

    previousVoxel = initialVoxel
    self.count = count ?? Int.max
  }

  public mutating func next() -> BlockPosition? {
    if count == 0 {
      return nil
    }

    count -= 1

    var voxel: Vec3i
    if isFirst {
      isFirst = false
      voxel = initialVoxel
    } else {
      voxel = previousVoxel

      let minBoundaryDistance: Float = MathUtil.abs(nextBoundaryDistance).min()
      if abs(nextBoundaryDistance.x) == minBoundaryDistance {
        nextBoundaryDistance.x += boundaryDistanceStep.x
        voxel.x += step.x
      } else if abs(nextBoundaryDistance.y) == minBoundaryDistance {
        nextBoundaryDistance.y += boundaryDistanceStep.y
        voxel.y += step.y
      } else {
        nextBoundaryDistance.z += boundaryDistanceStep.z
        voxel.z += step.z
      }
    }

    previousVoxel = voxel
    return BlockPosition(x: voxel.x, y: voxel.y, z: voxel.z)
  }
}
