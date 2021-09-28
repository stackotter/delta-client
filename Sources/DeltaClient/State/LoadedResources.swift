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
