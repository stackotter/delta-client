//
//  MessageComponent.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 7/6/21.
//

import Foundation

struct MessageComponent: LogComponent {
  var message: String
  
  func toString() -> String {
    return message
  }
}
