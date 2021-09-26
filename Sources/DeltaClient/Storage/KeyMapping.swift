//
//  KeyMapping.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 10/7/21.
//

import Foundation
import DeltaCore

struct KeyMapping {
  var mapping: [Input: Key]
  
  func getEvent(for key: Key) -> Input? {
    for (event, eventKey) in mapping {
      if key == eventKey {
        return event
      }
    }
    return nil
  }
}
