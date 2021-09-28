//
//  EventBatch.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 5/6/21.
//

import Foundation

public struct EventBatch {
  public var events: [Event] = []
  
  public var isEmpty: Bool {
    return events.isEmpty
  }
  
  public mutating func add(_ event: Event) {
    events.append(event)
  }
}
