//
//  PixlyzerBlockRenderDescriptor.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation

/// Describes what to render for a specific block state.
public enum PixlyzerBlockRenderDescriptor: Codable {
  case singleVariant(PixlyzerBlockModel)
  case multipleVariants([PixlyzerBlockModel])
  
  public init(from decoder: Decoder) throws {
    if let container = try? decoder.singleValueContainer() {
      let model = try container.decode(PixlyzerBlockModel.self)
      self = .singleVariant(model)
    } else if var container = try? decoder.unkeyedContainer() {
      var variants: [PixlyzerBlockModel] = []
      while !container.isAtEnd {
        let variant = try container.decode(PixlyzerBlockModel.self)
        variants.append(variant)
      }
      self = .multipleVariants(variants)
    } else {
      throw PixlyzerError.invalidBlockModel
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    switch self {
      case let .singleVariant(model):
        var container = encoder.singleValueContainer()
        try container.encode(model)
      case let .multipleVariants(variants):
        var container = encoder.unkeyedContainer()
        for variant in variants {
          try container.encode(variant)
        }
    }
  }
  
  var variants: [PixlyzerBlockModel] {
    switch self {
      case let .singleVariant(model):
        return [model]
      case let .multipleVariants(models):
        return models
    }
  }
}
