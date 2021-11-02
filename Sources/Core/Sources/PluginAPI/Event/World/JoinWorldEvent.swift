import Foundation

public struct JoinWorldEvent: Event {
  public var world: World
  public var viewDistance: Int
  
  public init(world: World, viewDistance: Int) {
    self.world = world
    self.viewDistance = viewDistance
  }
}
