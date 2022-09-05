/// Clientside configuration such as clientside render distance.
public struct ClientConfiguration {
  /// The configuration related to rendering.
  public var render: RenderConfiguration
  /// The configured keymap.
  public var keymap: Keymap

  /// Creates a new client configuration.
  /// - Parameters:
  ///   - render: See ``RenderConfiguration`` for the default values.
  ///   - keymap: See ``Keymap`` for the default bindings.
  public init(
    render: RenderConfiguration = RenderConfiguration(),
    keymap: Keymap = Keymap.default
  ) {
    self.render = render
    self.keymap = keymap
  }
}
