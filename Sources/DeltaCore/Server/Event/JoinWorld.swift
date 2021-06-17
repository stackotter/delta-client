//
//  JoinWorld.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 2/6/21.
//

import Foundation

extension Server.Event {
  struct JoinWorld: Event {
    var world: World
  }
}
