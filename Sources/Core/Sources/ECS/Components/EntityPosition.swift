import Foundation
import simd

/// A component storing an entity's position relative to the world.
///
/// Use ``smoothVector`` to get a position that smoothly changes from one position to the next.
/// The time taken to move to a new position is set by ``smoothingDelay``.
///
/// Modify the position by setting the respective components (``x``, ``y`` or ``z``), by setting
/// ``vector``, or by using ``move(to:)-7n5jq``, ``move(to:)-h7ig`` or ``move(by:)``. Do not directly set a
/// variable of type ``EntityPosition`` to a new value because that will break smoothing.
public struct EntityPosition {
  // MARK: Static properties
  
  /// How long to take to move to a new position.
  public static var smoothingDelay: Double = 1 / 15
  
  // MARK: Public properties
  
  /// The raw position (not smoothed).
  public var vector: SIMD3<Double> {
    get { _vector }
    set {
      previousVector = smoothVector
      _vector = newValue
      lastUpdated = CFAbsoluteTimeGetCurrent()
    }
  }
  
  /// The position but smoothly interpolated from a previous position to a new position over the course of a tick (20th of a second).
  public var smoothVector: SIMD3<Double> {
    let delta = CFAbsoluteTimeGetCurrent() - lastUpdated
    let tickProgress = min(max(delta / Self.smoothingDelay, 0), 1)
    return tickProgress * (_vector - previousVector) + previousVector
  }
  
  /// The raw x coordinate (not smoothed).
  public var x: Double {
    get { vector.x }
    set {
      var copy = vector
      copy.x = newValue
      vector = copy
    }
  }
  
  /// The raw y coordinate (not smoothed).
  public var y: Double {
    get { vector.y }
    set {
      var copy = vector
      copy.y = newValue
      vector = copy
    }
  }
  
  /// The raw z coordinate (not smoothed).
  public var z: Double {
    get { vector.z }
    set {
      var copy = vector
      copy.z = newValue
      vector = copy
    }
  }
  
  /// The position of the chunk this position is in.
  public var chunk: ChunkPosition {
    return ChunkPosition(
      chunkX: Int((x / 16).rounded(.down)),
      chunkZ: Int((z / 16).rounded(.down)))
  }
  
  // MARK: Private properties
  
  /// The underlying vector.
  private var _vector: SIMD3<Double>
  /// The previous position.
  private var previousVector: SIMD3<Double>
  /// The time the vector was last updated. Used for smoothing.
  private var lastUpdated: CFAbsoluteTime
  
  // MARK: Init
  
  /// Creates an entity position from a vector.
  public init(_ vector: SIMD3<Double>) {
    _vector = vector
    previousVector = vector
    lastUpdated = CFAbsoluteTimeGetCurrent()
  }
  
  /// Creates an entity position from coordinates.
  public init(x: Double, y: Double, z: Double) {
    self.init(SIMD3<Double>(x, y, z))
  }
  
  // MARK: Updating
  
  /// Moves the position to a new specified smoothing and will interpolate the position between the two over the course of a ``smoothingDelay``.
  public mutating func move(to position: EntityPosition) {
    vector = position.vector
  }
  
  /// Moves the position to a new specified smoothing and will interpolate the position between the two over the course of a ``smoothingDelay``.
  public mutating func move(to position: SIMD3<Double>) {
    vector = position
  }
  
  /// Offsets the position by a specified amount. This will smoothly transition to the new position over the course of a ``smoothingDelay``.
  public mutating func move(by offset: SIMD3<Double>) {
    vector += offset
  }
}
