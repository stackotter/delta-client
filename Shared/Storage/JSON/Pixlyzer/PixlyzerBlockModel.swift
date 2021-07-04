//
//  PixlyzerBlockModel.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import DeltaCore

public enum PixlyzerBlockModel: Codable {
  case simple(PixlyzerBlockModelDescriptor)
  case multipart([PixlyzerBlockModelDescriptor])
  
  public init(from decoder: Decoder) throws {
    if let container = try? decoder.singleValueContainer() {
      let modelDescriptor = try container.decode(PixlyzerBlockModelDescriptor.self)
      self = .simple(modelDescriptor)
    } else if var container = try? decoder.unkeyedContainer() {
      var parts: [PixlyzerBlockModelDescriptor] = []
      while !container.isAtEnd {
        let modelDescriptor = try container.decode(PixlyzerBlockModelDescriptor.self)
        parts.append(modelDescriptor)
      }
      self = .multipart(parts)
    } else {
      throw PixlyzerError.invalidBlockModelVariant
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    switch self {
      case let .simple(descriptor):
        var container = encoder.singleValueContainer()
        try container.encode(descriptor)
      case let .multipart(descriptors):
        var container = encoder.unkeyedContainer()
        for descriptor in descriptors {
          try container.encode(descriptor)
        }
    }
  }
  
  var parts: [PixlyzerBlockModelDescriptor] {
    switch self {
      case let .simple(descriptor):
        return [descriptor]
      case let .multipart(descriptors):
        return descriptors
    }
  }
}
