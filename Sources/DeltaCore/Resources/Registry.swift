//
//  Registry.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 4/7/21.
//

import Foundation

public class Registry {
  public var blockRegistry: BlockRegistry
  
  public init(blockRegistry: BlockRegistry) {
    self.blockRegistry = blockRegistry
  }
}
