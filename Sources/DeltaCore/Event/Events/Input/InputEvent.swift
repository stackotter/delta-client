//
//  InputEvent.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 10/7/21.
//

import Foundation

public struct InputEvent: Event {
  public var type: InputEventType
  public var input: Input
  
  public init(type: InputEventType, input: Input) {
    self.type = type
    self.input = input
  }
}
