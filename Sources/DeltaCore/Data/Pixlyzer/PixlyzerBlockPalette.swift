//
//  PixlyzerBlockPalette.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation

public struct PixlyzerBlockPalette {
  public var palette: [Identifier: PixlyzerBlock]
}

extension PixlyzerBlockPalette: Decodable {
  public init(from decoder: Decoder) throws {
    palette = [:]
    
    let intermediate = try decoder.singleValueContainer().decode([String: PixlyzerBlock].self)
    for (key, value) in intermediate {
      let identifier = try Identifier(key)
      palette[identifier] = value
    }
  }
}
