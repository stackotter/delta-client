//
//  Random.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 12/4/21.
//

import Foundation
import GameplayKit

public class Random {
  let rand: GKLinearCongruentialRandomSource
  
  init(_ seed: UInt64) {
    self.rand = GKLinearCongruentialRandomSource(seed: seed)
  }
  
  public func nextLong() -> Int64 {
    return Int64(rand.nextInt())
  }
}
