/// Configuration for ``RenderCoordinator``.
public struct RenderConfiguration: Codable {
  /// The vertical fov in degrees.
  public var fovY: Float
  /// The furthest distance that chunks should be rendered at.
  ///
  /// The distance between a chunk and the camera is measure like so:
  /// ```swift
  /// let difference = chunk - cameraChunk
  /// let distance = max(difference.x, difference.z)
  /// ```
  public var renderDistance: Int
  /// The rendering mode to use.
  public var mode: RenderMode
  
  /// Creates a new render configuration.
  /// - Parameters:
  ///   - fovY: See ``fovY``. Defaults to 70 degrees.
  ///   - renderDistance: See ``renderDistance``. Defaults to 10.
  ///   - mode: See ``mode``. Defaults to ``RenderMode/normal``.
  public init(fovY: Float = 70, renderDistance: Int = 10, mode: RenderMode = .normal) {
    self.fovY = fovY
    self.renderDistance = renderDistance
    self.mode = mode
  }
}
