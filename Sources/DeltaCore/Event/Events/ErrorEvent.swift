//
//  JoinWorldEvent.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 2/7/21.
//

import Foundation

public struct ErrorEvent: Event {
  public var error: Error
  public var message: String?
  
  public init(error: Error, message: String? = nil) {
    self.error = error
    self.message = message
  }
}
