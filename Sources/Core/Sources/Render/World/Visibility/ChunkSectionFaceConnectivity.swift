/// Stores which pairs faces in a chunk section are connected to each other. Not threadsafe.
///
/// ``setConnected(_:_:)`` and ``setDisconnected(_:_:)`` are separate functions because this allows
/// branching to be eliminated and in most cases the parameter specifying whether they are connected
/// or not would be hardcoded anyway.
///
/// The efficiency of this storage method comes from using a bit field as the underlying storage and
/// using ``ChunkSectionFace``'s raw values to efficiently identify each pair of faces. See
/// ``ChunkSectionFace`` for a more detailed explanation.
public struct ChunkSectionFaceConnectivity: Equatable {
  // MARK: Public properties
  
  /// The connectivity for a fully connected chunk section.
  public static let fullyConnected = ChunkSectionFaceConnectivity(bitField: 0xffffffff)
  
  // MARK: Private properties
  
  /// The underlying storage for the connectivity information.
  private var bitField: UInt32 = 0
  
  // MARK: Init
  
  /// Creates an empty connectivity graph where none of the faces are connected.
  public init() {}
  
  /// Only use if you know what you're doing.
  /// - Parameter bitField: Initial value of the underlying bitfield.
  private init(bitField: UInt32) {
    self.bitField = bitField
  }
  
  // MARK: Public methods
  
  /// Marks a pair of faces as connected.
  /// - Parameters:
  ///   - firstFace: The first face.
  ///   - secondFace: The seconds face.
  public mutating func setConnected(_ firstFace: ChunkSectionFace, _ secondFace: ChunkSectionFace) {
    let hashValue = firstFace.rawValue + secondFace.rawValue
    bitField |= 1 << hashValue
  }
  
  /// Marks a pair of faces as disconnected.
  /// - Parameters:
  ///   - firstFace: The first face.
  ///   - secondFace: The second face.
  public mutating func setDisconnected(_ firstFace: ChunkSectionFace, _ secondFace: ChunkSectionFace) {
    let hashValue = firstFace.rawValue + secondFace.rawValue
    bitField ^= ~(1 << hashValue)
  }
  
  /// Gets whether a pair of faces are connected or not.
  /// - Parameters:
  ///   - firstFace: The first face.
  ///   - secondFace: The second face.
  /// - Returns: Whether the faces are connected or not.
  public func areConnected(_ firstFace: ChunkSectionFace, _ secondFace: ChunkSectionFace) -> Bool {
    let hashValue = firstFace.rawValue + secondFace.rawValue
    return bitField & (1 << hashValue) != 0
  }
}
