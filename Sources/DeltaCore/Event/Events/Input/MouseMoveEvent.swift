//
//  MouseMoveEvent.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 10/7/21.
//

import Foundation

public struct MouseMoveEvent: Event {
  public var deltaX: Float
  public var deltaY: Float
  
  public init(deltaX: Float, deltaY: Float) {
    self.deltaX = deltaX
    self.deltaY = deltaY
  }
}
