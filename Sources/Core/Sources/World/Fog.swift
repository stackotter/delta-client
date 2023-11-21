/// The distance fog experienced by a player.
public struct Fog {
  public var color: Vec3f
  public var style: Style

  public enum Style {
    case exponential(density: Float)
    case linear(startDistance: Float, endDistance: Float)
  }
}
