import Metal

/// An array texture that supports animated textures.
public struct AnimatedArrayTexture {
  /// The underlying array texture.
  public var texture: MTLTexture
  /// The texture palette containing all textures and animation information.
  public var palette: TexturePalette
  /// The current state of all animated textures in the palette.
  ///
  /// Updated everytime ``update(tick:device:commandQueue:)`` is called.
  public var state: ArrayTextureAnimationState
  
  /// Creates a new animated array texture for the given texture palette.
  public init(palette: TexturePalette, device: MTLDevice, commandQueue: MTLCommandQueue) throws {
    self.palette = palette
    state = ArrayTextureAnimationState(for: palette)
    texture = try palette.createTextureArray(device: device, animationState: state, commandQueue: commandQueue)
  }
  
  /// Updates any frames that have changed between the last update and the current tick.
  public mutating func update(tick: Int, device: MTLDevice, commandQueue: MTLCommandQueue) {
    let updatedTextures = state.update(tick: tick)
    palette.updateArrayTexture(
      arrayTexture: texture,
      animationState: state,
      updatedTextures: updatedTextures,
      commandQueue: commandQueue)
  }
}
