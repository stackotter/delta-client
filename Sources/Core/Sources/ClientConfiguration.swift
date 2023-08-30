/// Clientside configuration such as keymap and clientside render distance.
/// Any package creating a Client instance should implement this protocol to allow DeltaCore to access configuration values.
public protocol ClientConfiguration {
  /// The configuration related to rendering.
  var render: RenderConfiguration { get }
  /// The configured keymap.
  var keymap: Keymap { get }
  /// Whether to use the sprint key as a toggle.
  var toggleSprint: Bool { get }
  /// Whether to use the sneak key as a toggle.
  var toggleSneak: Bool { get }
}
