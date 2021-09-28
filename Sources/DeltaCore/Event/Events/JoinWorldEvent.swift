//
//  JoinWorldEvent.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 2/7/21.
//

import Foundation

public struct JoinWorldEvent: Event {
  public var world: World
  
  public init(world: World) {
    self.world = world
  }
}
