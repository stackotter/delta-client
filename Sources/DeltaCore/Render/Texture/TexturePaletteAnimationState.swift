import Foundation

public struct TexturePaletteAnimationState {
  /// The last tick processed.
  public var lastTick: Int?
  /// The states of all animated textures.
  public var animationStates: [Int: TextureAnimationState]
  
  public init(for palette: TexturePalette) {
    animationStates = [:]
    for (index, texture) in palette.textures.enumerated() {
      if let animation = texture.animation {
        animationStates[index] = TextureAnimationState(for: animation)
      }
    }
  }
  
  /// Updates all animation states and returns the indices of all textures that changed frames.
  public mutating func update(tick: Int) -> [Int] {
    var numTicks = 0
    if let lastTick = lastTick {
      numTicks = tick - lastTick
    }
    lastTick = tick
    
    if numTicks <= 0 {
      return []
    }
    
    var updatedTextures: Set<Int> = []
    for _ in 0..<numTicks {
      for (index, var state) in animationStates {
        let hasChangedFrames = state.tick()
        if hasChangedFrames {
          updatedTextures.insert(index)
        }
        animationStates[index] = state
      }
    }
    return [Int](updatedTextures)
  }
  
  /// Returns the frame to render for the given texture.
  public func frame(forTextureAt index: Int) -> Int {
    if let state = animationStates[index] {
      return state.currentFrame
    } else {
      return 0
    }
  }
}
