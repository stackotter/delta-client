//
//  SingleOrMultiple.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 4/7/21.
//

import Foundation

/// A type container for Mojang and Pixlyzer's weird JSON formats. The formats sometimes have
/// keys that can either contain a single value or an array depending on context.
public enum SingleOrMultiple<T: Decodable>: Decodable {
  /// Contains a single value. In JSON it is just a value.
  case single(T)
  /// Contains multiple values. In JSON it is an array.
  case multiple([T])
  
  /// The container's elements as an array.
  var items: [T] {
    switch self {
      case let .single(item):
        return [item]
      case let .multiple(items):
        return items
    }
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    // It's a bit dodgy but we have to check for multiple before single otherwise decoding
    // PixlyzerBlockState.renderDescriptor doesn't work (for a nested SingleOrMultiple)
    if let items = try? container.decode([T].self) {
      self = .multiple(items)
    } else if let item = try? container.decode(T.self) {
      self = .single(item)
    } else {
      throw JSONError.invalidSingleOrMultipleElement
    }
  }
}
