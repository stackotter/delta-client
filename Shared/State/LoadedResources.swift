//
//  LoadedResources.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 8/8/21.
//

import Foundation
import DeltaCore

class LoadedResources {
  var resourcePack: ResourcePack
  var registry: Registry
  
  init(resourcePack: ResourcePack, registry: Registry) {
    self.resourcePack = resourcePack
    self.registry = registry
  }
}
