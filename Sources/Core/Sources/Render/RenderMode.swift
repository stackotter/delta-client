/// All of the supported rendering modes.
public enum RenderMode: String, Codable, CaseIterable, Identifiable {
  /// Regular rendering.
  case normal
  /// Wireframe rendering.
  case wireframe
  
  public var id: Self { self }
}
