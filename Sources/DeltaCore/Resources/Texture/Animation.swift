//
//  Animation.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 16/7/21.
//

import Foundation

extension Texture {
  /// Metadata for an animated texture.
  public struct Animation {
    public var interpolate: Bool
    public var frames: [Frame]
    
    public init(interpolate: Bool, frames: [Frame]) {
      self.interpolate = interpolate
      self.frames = frames
    }
    
    /// `textureFrames` is the number of frames present in the corresponding texture.
    public init(from mcMeta: AnimationMCMeta, maxFrameIndex: Int) {
      interpolate = mcMeta.animation.interpolate ?? false
      
      // Reformat frames
      frames = []
      let defaultFrameTime = mcMeta.animation.frametime ?? 1
      if let mcMetaFrames = mcMeta.animation.frames {
        for mcMetaFrame in mcMetaFrames {
          let frame = Frame(
            index: mcMetaFrame.index,
            time: mcMetaFrame.time ?? defaultFrameTime)
          frames.append(frame)
        }
      } else {
        for i in 0..<maxFrameIndex {
          let frame = Frame(
            index: i,
            time: defaultFrameTime)
          frames.append(frame)
        }
      }
    }
  }
}

extension Texture.Animation {
  public struct Frame {
    public var index: Int
    public var time: Int
  }
}
