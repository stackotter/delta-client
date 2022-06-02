/// Clientside configuration such as clientside render distance.
public struct ClientConfiguration {
  /// The configuration related to rendering.
  public var render = RenderConfiguration()
  
  /// Creates a new client configuration.
  /// - Parameter render: See ``RenderConfiguration`` for the default values.
  public init(render: RenderConfiguration = RenderConfiguration()) {
    self.render = render
  }
}
