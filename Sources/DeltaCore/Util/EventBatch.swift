//
//  EventBatch.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 5/6/21.
//

import Foundation

struct EventBatch {
  var events: [Event] = []
  
  var isEmpty: Bool {
    return events.isEmpty
  }
  
  mutating func add(_ event: Event) {
    events.append(event)
  }
}
