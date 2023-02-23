import Foundation

extension TexturePalette {
  public struct AnimationState {
    /// The last tick processed.
    public var lastTick: Int?
    /// The states of all animated textures.
    public var animationStates: [Int: Texture.AnimationState]

    public init(for textures: [Texture]) {
      animationStates = [:]
      for (index, texture) in textures.enumerated() {
        if let animation = texture.animation {
          animationStates[index] = Texture.AnimationState(for: animation)
        }
      }
    }

    /// Updates all animation states and returns the indices of all textures that changed frames.
    public mutating func update(tick: Int) -> [(index: Int, tick: Int)] {
      var numTicks = 0
      if let lastTick = lastTick {
        numTicks = tick - lastTick
      }
      lastTick = tick

      if numTicks <= 0 {
        return []
      }

      var updatedTextures: [(index: Int, tick: Int)] = []
      for i in 0..<numTicks {
        for (index, var state) in animationStates {
          let hasChangedFrames = state.tick()
          if hasChangedFrames {
            updatedTextures.append((index: index, tick: tick + i))
          }
          animationStates[index] = state
        }
      }

      var seenIndices: Set<Int> = []
      let filtered = updatedTextures.reversed().filter { (index, tick) in
        return seenIndices.insert(index).inserted
      }
      return filtered
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
}
