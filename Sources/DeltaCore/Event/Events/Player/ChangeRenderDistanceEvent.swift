//
//  ChangeRenderDistanceEvent.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 10/7/21.
//

import Foundation

/// An event triggered to update the player's render distance.
public struct ChangeRenderDistanceEvent: Event {
  /// The new render distance.
  public var renderDistance: Int
  
  public init(renderDistance: Int) {
    self.renderDistance = renderDistance
  }
}
