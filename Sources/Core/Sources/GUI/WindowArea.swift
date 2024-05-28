/// An area of a GUI window; a grid of slots. Only handles areas where the rows
/// are stored one after another in the window's slot array.
public struct WindowArea {
  /// Index of the first slot in the area.
  public var startIndex: Int
  /// Number of slots wide.
  public var width: Int
  /// Number of slots high.
  public var height: Int
  /// The position of the area within its window.
  public var position: Vec2i
}
