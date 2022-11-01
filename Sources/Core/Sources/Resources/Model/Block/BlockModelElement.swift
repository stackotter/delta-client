import Foundation
import FirebladeMath

/// A block model element is a rectangular prism. All block models are built from elements.
public struct BlockModelElement {
  /// First of two vertices defining this rectangular prism.
  public var transformation: Mat4x4f
  /// Whether to render shadows or not.
  public var shade: Bool
  /// The faces present on this element.
  public var faces: [BlockModelFace] = []

  public init(transformation: Mat4x4f, shade: Bool, faces: [BlockModelFace]) {
    self.transformation = transformation
    self.shade = shade
    self.faces = faces
  }
}
