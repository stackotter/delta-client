extension Block {
  /// Material sound related properties of a block.
  public struct SoundMaterial: Codable {
    /// Volume of sounds emitted by this block.
    public var volume: Double
    /// Pitch of sounds emitted by this block.
    public var pitch: Double
    /// Sound to play when the block is broken.
    public var breakSound: Int
    /// Sound to play when this block is walked on.
    public var stepSound: Int
    /// Sound to play when this block is placed.
    public var placeSound: Int
    /// Sound to play when this block is hit.
    public var hitSound: Int
    /// Sound to play when something falls onto this block?
    public var fallSound: Int
    
    public init(
      volume: Double,
      pitch: Double,
      breakSound: Int,
      stepSound: Int,
      placeSound: Int,
      hitSound: Int,
      fallSound: Int
    ) {
      self.volume = volume
      self.pitch = pitch
      self.breakSound = breakSound
      self.stepSound = stepSound
      self.placeSound = placeSound
      self.hitSound = hitSound
      self.fallSound = fallSound
    }
    
    /// Used for missing blocks.
    public static var `default` = SoundMaterial(
      volume: 0,
      pitch: 0,
      breakSound: -1,
      stepSound: -1,
      placeSound: -1,
      hitSound: -1,
      fallSound: -1)
  }
}
