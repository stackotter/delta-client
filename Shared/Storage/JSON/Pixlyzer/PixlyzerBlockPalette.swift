//
//  PixlyzerBlockPalette.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import DeltaCore

public struct PixlyzerBlockPalette {
  public var palette: [Identifier: PixlyzerBlock]
}

extension PixlyzerBlockPalette: Codable {
  public init(from decoder: Decoder) throws {
    palette = [:]
    
    let intermediate = try decoder.singleValueContainer().decode([String: PixlyzerBlock].self)
    for (key, value) in intermediate {
      let identifier = try Identifier(key)
      palette[identifier] = value
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    var intermediate: [String: PixlyzerBlock] = [:]
    for (key, value) in palette {
      intermediate[key.description] = value
    }
    try container.encode(intermediate)
  }
}
