//
//  AnimationMCMeta.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 16/7/21.
//

import Foundation

/// The format of an mcmeta file describing a block texture's animation.
public struct AnimationMCMeta: Decodable {
  public var animation: Animation
}

extension AnimationMCMeta {
  public struct Animation: Decodable {
    public var interpolate: Bool?
    public var width: Int?
    public var height: Int?
    public var frametime: Int?
    public var frames: [Frame]?
  }
}

extension AnimationMCMeta {
  public struct Frame: Decodable {
    public var index: Int
    public var time: Int?
    
    private enum CodingKeys: String, CodingKey {
      case index
      case time
    }
    
    public init(from decoder: Decoder) throws {
      if let container = try? decoder.singleValueContainer() {
        index = try container.decode(Int.self)
      } else if let container = try? decoder.container(keyedBy: CodingKeys.self) {
        index = try container.decode(Int.self, forKey: .index)
        time = try container.decode(Int.self, forKey: .time)
      } else {
        throw TextureError.invalidFrameMetadata
      }
    }
  }
}
