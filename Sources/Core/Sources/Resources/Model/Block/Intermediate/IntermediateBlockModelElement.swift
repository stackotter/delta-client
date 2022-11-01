import Foundation
import FirebladeMath

/// Flattened mojang block model element format.
struct IntermediateBlockModelElement {
  /// The minimum vertex of the element. For a dirt block this would be (0, 0, 0).
  var from: Vec3f
  /// The maximum vertex of the element. For a dirt block this would be (1, 1, 1).
  var to: Vec3f
  /// The rotation matrix for this block model.
  var rotation: IntermediateBlockModelElementRotation?
  /// Whether to render shadows or not.
  var shouldShade: Bool
  /// The faces present on this element.
  var faces: [IntermediateBlockModelFace]

  /// Creates a neater and flattened version of a Mojang formatted block model.
  init(from mojangElement: JSONBlockModelElement, with textureVariables: [String: String]) throws {
    let blockSize: Float = 16

    // Convert the arrays of doubles to vectors and scale so that they are the same scale as world space
    let from = try MathUtil.vectorFloat3(from: mojangElement.from) / blockSize
    let to = try MathUtil.vectorFloat3(from: mojangElement.to) / blockSize

    // I don't trust mojang so this makes sure from and to are actually the minimum and maximum vertices of the element
    self.from = MathUtil.min(from, to)
    self.to = MathUtil.max(from, to)

    if let mojangRotation = mojangElement.rotation {
      rotation = try IntermediateBlockModelElementRotation(from: mojangRotation)
    }

    shouldShade = mojangElement.shade ?? true

    faces = try mojangElement.faces.map { (directionString, mojangFace) in
      guard let mojangDirection = JSONBlockModelFaceName(rawValue: directionString) else {
        throw BlockModelPaletteError.invalidDirectionString(directionString)
      }
      return IntermediateBlockModelFace(
        from: mojangFace,
        facing: mojangDirection,
        with: textureVariables)
    }
  }

  /// Updates the element's faces' textures with a dictionary of texture variables.
  /// This is the main part of the flattening process (to remove texture variable lookups later on.
  mutating func updateTextures(with textureVariables: [String: String]) {
    for (index, var face) in faces.enumerated() {
      face.updateTexture(with: textureVariables)
      faces[index] = face
    }
  }

  /// The transformation matrix to apply to a 1x1x1 cube to get this element.
  var transformationMatrix: Mat4x4f {
    let scale = to - from
    var matrix = MatrixUtil.scalingMatrix(scale)
    matrix *= MatrixUtil.translationMatrix(from)
    if let rotation = rotation {
      matrix *= rotation.matrix
    }

    return matrix
  }

  /// Returns which directions this block has full faces in.
  func getCullingFaces() -> Set<Direction> {
    // There cannot be a full face if the element has rotation not a multiple of 90 degrees.
    // The only possible multiple of 90 degrees is 0 in this case
    if (rotation?.radians ?? 0) != 0 {
      return []
    }

    // Since rotation is 0 we can just ignore it now.
    var cullFaces: Set<Direction> = []

    // Checking north, down and west faces (negative directions)
    if from == Vec3f(repeating: 0) {
      if to.x == 1 && to.y == 1 {
        cullFaces.insert(.north)
      }
      if to.x == 1 && to.z == 1 {
        cullFaces.insert(.down)
      }
      if to.y == 1 && to.z == 1 {
        cullFaces.insert(.west)
      }
    }

    // Checking south, up and east faces (positive directions)
    if to == Vec3f(repeating: 1) {
      if from.x == 0 && from.y == 0 {
        cullFaces.insert(.south)
      }
      if from.x == 0 && from.z == 0 {
        cullFaces.insert(.up)
      }
      if from.y == 0 && from.z == 0 {
        cullFaces.insert(.east)
      }
    }

    return cullFaces
  }
}
