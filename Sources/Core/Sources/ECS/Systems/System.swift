import FirebladeECS

public protocol System {
  func update(_ nexus: Nexus, _ world: World) throws
}
