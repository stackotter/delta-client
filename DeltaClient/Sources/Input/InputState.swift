//
//  InputState.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 30/5/21.
//

import Foundation
import simd
import AppKit

struct InputState {
  var pressedKeys = Set<UInt16>()
  var modifierFlags = NSEvent.ModifierFlags()
  
  var mouseDelta: simd_float2 = [0, 0]
  
  mutating func resetMouseDelta() {
    mouseDelta = [0, 0]
  }
}
