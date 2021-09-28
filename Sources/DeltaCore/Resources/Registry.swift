import Foundation

public class Registry {
  public var blockRegistry: BlockRegistry
  
  public init(blockRegistry: BlockRegistry) {
    self.blockRegistry = blockRegistry
  }
}
