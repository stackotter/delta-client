import Foundation
import simd
import FirebladeECS

/// A component storing an entity's position relative to the world.
///
/// Use ``smoothVector`` to get a vector that changes smoothly (positions are usually only updated once per tick).
public class EntityPosition: Component {
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
  
  /// The amount of time taken (in seconds) for ``smoothVector`` to transition from one position to the next.
  public var smoothingAmount: Double
  
  /// A vector that smoothly interpolates from the previous position to the next position in an amount of time described by ``smoothingAmount``.
  public var smoothVector: SIMD3<Double> {
    let delta = CFAbsoluteTimeGetCurrent() - lastUpdated
    let tickProgress = min(max(delta / smoothingAmount, 0), 1)
    return tickProgress * (_vector - previousVector) + previousVector
  }
  
  /// The raw x component (not smoothed).
  public var x: Double {
    get { vector.x }
    set {
      var copy = vector
      copy.x = newValue
      vector = copy
    }
  }
  
  /// The raw y component (not smoothed).
  public var y: Double {
    get { vector.y }
    set {
      var copy = vector
      copy.y = newValue
      vector = copy
    }
  }
  
  /// The raw z component (not smoothed).
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
  
  /// The position of the chunk section this position is in.
  public var chunkSection: ChunkSectionPosition {
    return ChunkSectionPosition(
      sectionX: Int((x / 16).rounded(.down)),
      sectionY: Int((y / 16).rounded(.down)),
      sectionZ: Int((z / 16).rounded(.down)))
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
  /// - Parameters:
  ///   - vector: A vector representing the position.
  ///   - smoothingAmount: The amount of time (in seconds) for ``smoothVector`` to transition from one position to the next. Defaults to one 15th of a second.
  public init(_ vector: SIMD3<Double>, smoothingAmount: Double = 1 / 15) {
    _vector = vector
    previousVector = vector
    lastUpdated = CFAbsoluteTimeGetCurrent()
    self.smoothingAmount = smoothingAmount
  }
  
  /// Creates an entity position from coordinates.
  /// - Parameters:
  ///   - x: x coordinate.
  ///   - y: y coordinate.
  ///   - z: z coordinate.
  ///   - smoothingAmount: The amount of time (in seconds) for ``smoothVector`` to transition from one position to the next. Defaults to one 15th of a second.
  public convenience init(_ x: Double, _ y: Double, _ z: Double, smoothingAmount: Double = 1 / 15) {
    self.init(SIMD3<Double>(x, y, z), smoothingAmount: smoothingAmount)
  }
  
  // MARK: Updating
  
  /// Moves the position to a new specified smoothing and will interpolate the position between the two over the course of a ``smoothingDelay``.
  public func move(to position: EntityPosition) {
    vector = position.vector
  }
  
  /// Moves the position to a new specified smoothing and will interpolate the position between the two over the course of a ``smoothingDelay``.
  public func move(to position: SIMD3<Double>) {
    vector = position
  }
  
  /// Offsets the position by a specified amount. This will smoothly transition to the new position over the course of a ``smoothingDelay``.
  public func move(by offset: SIMD3<Double>) {
    vector += offset
  }
}
