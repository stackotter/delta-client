/// Configuration for ``RenderCoordinator``.
public struct RenderConfiguration: Codable {
  /// The vertical fov in degrees.
  public var fovY: Float
  /// The furthest distance that chunks should be rendered at.
  ///
  /// The distance between a chunk and the camera is measured like so:
  /// ```swift
  /// let difference = chunk - cameraChunk
  /// let distance = max(difference.x, difference.z)
  /// ```
  public var renderDistance: Int
  /// The rendering mode to use.
  public var mode: RenderMode
  /// Enables the order independent transparency optimization.
  public var enableOrderIndependentTransparency: Bool

  /// Creates a new render configuration.
  /// - Parameters:
  ///   - fovY: See ``fovY``. Defaults to 70 degrees.
  ///   - renderDistance: See ``renderDistance``. Defaults to 10.
  ///   - mode: See ``mode``. Defaults to ``RenderMode/normal``.
  ///   - enableOrderIndependentTransparency: See ``enableOrderIndependentTransparency``. Defaults
  ///     to `false`.
  public init(
    fovY: Float = 70,
    renderDistance: Int = 10,
    mode: RenderMode = .normal,
    enableOrderIndependentTransparency: Bool = false
  ) {
    self.fovY = fovY
    self.renderDistance = renderDistance
    self.mode = mode
    self.enableOrderIndependentTransparency = enableOrderIndependentTransparency
  }
}
