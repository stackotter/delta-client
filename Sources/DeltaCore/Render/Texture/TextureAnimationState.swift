//
//  TextureAnimationState.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 18/7/21.
//

import Foundation

public struct TextureAnimationState {
  public var animation: Texture.Animation
  
  public var index: Int
  public var ticksRemaining: Int
  
  /// The current frame being shown for this texture.
  public var currentFrame: Int {
    animation.frames[index].index
  }
  
  public init(for animation: Texture.Animation) {
    self.animation = animation
    index = 0
    ticksRemaining = animation.frames[0].time
  }
  
  /// Progresses the animation by one tick. Returns whether the current frame changed or not.
  public mutating func tick() -> Bool {
    ticksRemaining -= 1
    if ticksRemaining == 0 {
      index = (index + 1) % animation.frames.count
      ticksRemaining = animation.frames[index].time
      return true
    } else {
      return false
    }
  }
}
