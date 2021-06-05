//
//  SetBlock.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 1/6/21.
//

import Foundation

extension World.Event {
  struct SetBlock: Event {
    var position: Position
    var newState: UInt16
  }
}
