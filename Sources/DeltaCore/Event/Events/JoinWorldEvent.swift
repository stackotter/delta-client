import Foundation

public struct JoinWorldEvent: Event {
  public var world: World
  
  public init(world: World) {
    self.world = world
  }
}
