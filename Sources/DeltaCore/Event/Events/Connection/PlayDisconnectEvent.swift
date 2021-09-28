//
//  PlayDisconnectEvent.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 8/7/21.
//

import Foundation

public struct PlayDisconnectEvent: Event {
  public var reason: String
  
  public init(reason: String) {
    self.reason = reason
  }
}
