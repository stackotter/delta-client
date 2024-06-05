import CoreFoundation
import DeltaCore

public struct EntityMeshBuilder {
  /// Associates entity kinds with hardcoded entity texture identifiers. Used to manually
  /// instruct Delta Client where to find certain textures that aren't in the standard
  /// locations.
  static let hardcodedTextureIdentifiers: [Identifier: Identifier] = [
    Identifier(name: "player"): Identifier(name: "entity/steve"),
    Identifier(name: "dragon"): Identifier(name: "entity/enderdragon/dragon"),
  ]

  let entityKind: Identifier
  let model: JSONEntityModel
  let position: Vec3f
  let pitch: Float
  let yaw: Float
  let texturePalette: MetalTexturePalette

  static let colors: [Vec3f] = [
    [1, 0, 0],
    [0, 1, 0],
    [0, 0, 1],
    [1, 1, 0],
    [1, 0, 1],
    [0, 1, 1],
    [0, 0, 0],
    [1, 1, 1],
  ]

  func build(into geometry: inout Geometry<EntityVertex>) {
    let texture: Int?
    if let identifier = Self.hardcodedTextureIdentifiers[entityKind] {
      texture = texturePalette.textureIndex(for: identifier)
    } else {
      // Entity textures can be in all sorts of structures so we just have a few
      // educated guesses for now.
      let textureIdentifier = Identifier(
        namespace: entityKind.namespace,
        name: "entity/\(entityKind.name)"
      )
      let nestedTextureIdentifier = Identifier(
        namespace: entityKind.namespace,
        name: "entity/\(entityKind.name)/\(entityKind.name)"
      )
      texture =
        texturePalette.textureIndex(for: textureIdentifier)
        ?? texturePalette.textureIndex(for: nestedTextureIdentifier)
    }

    for (index, submodel) in model.models.enumerated() {
      buildSubmodel(submodel, index: index, textureIndex: texture, into: &geometry)
    }
  }

  func buildSubmodel(
    _ submodel: JSONEntityModel.Submodel,
    index: Int,
    textureIndex: Int?,
    transformation: Mat4x4f = MatrixUtil.identity,
    into geometry: inout Geometry<EntityVertex>
  ) {
    var transformation = transformation
    if let rotation = submodel.rotate {
      let translation = submodel.translate ?? .zero
      transformation =
        MatrixUtil.rotationMatrix(-MathUtil.radians(from: rotation))
        * MatrixUtil.translationMatrix(translation)
    }

    for box in submodel.boxes ?? [] {
      buildBox(
        box,
        color: index < Self.colors.count ? Self.colors[index] : [0.5, 0.5, 0.5],
        transformation: transformation,
        textureIndex: textureIndex,
        // We already invert 'y' and 'z'
        invertedAxes: [
          submodel.invertAxis?.contains("x") == true,
          submodel.invertAxis?.contains("y") != true,
          submodel.invertAxis?.contains("z") != true,
        ],
        into: &geometry
      )
    }

    for (nestedIndex, nestedSubmodel) in (submodel.submodels ?? []).enumerated() {
      buildSubmodel(
        nestedSubmodel,
        index: nestedIndex,
        textureIndex: textureIndex,
        transformation: transformation,
        into: &geometry
      )
    }
  }

  func buildBox(
    _ box: JSONEntityModel.Box,
    color: Vec3f,
    transformation: Mat4x4f,
    textureIndex: Int?,
    invertedAxes: [Bool],
    into geometry: inout Geometry<EntityVertex>
  ) {
    var boxPosition = Vec3f(
      box.coordinates[0],
      box.coordinates[1],
      box.coordinates[2]
    )
    var boxSize = Vec3f(
      box.coordinates[3],
      box.coordinates[4],
      box.coordinates[5]
    )

    let textureOffset = Vec2f(box.textureOffset ?? .zero)

    let baseBoxSize = boxSize
    if let additionalSize = box.sizeAdd {
      let growth = Vec3f(repeating: additionalSize)
      boxPosition -= growth
      boxSize += 2 * growth
    }

    for direction in Direction.allDirections {
      // The index of the first vertex of this face
      let offset = UInt32(geometry.vertices.count)
      for index in CubeGeometry.faceWinding {
        geometry.indices.append(index &+ offset)
      }

      var uvOrigin: Vec2f
      var uvSize: Vec2f
      let verticalAxis: Axis
      let horizontalAxis: Axis
      switch direction {
        case .east:
          uvOrigin = textureOffset + Vec2f(0, baseBoxSize.z)
          uvSize = Vec2f(baseBoxSize.z, baseBoxSize.y)
          verticalAxis = .y
          horizontalAxis = .z
        case .north:
          uvOrigin = textureOffset + Vec2f(baseBoxSize.z, baseBoxSize.z)
          uvSize = Vec2f(baseBoxSize.x, baseBoxSize.y)
          verticalAxis = .y
          horizontalAxis = .x
        case .west:
          uvOrigin = textureOffset + Vec2f(baseBoxSize.z + baseBoxSize.x, baseBoxSize.z)
          uvSize = Vec2f(baseBoxSize.z, baseBoxSize.y)
          verticalAxis = .y
          horizontalAxis = .z
        case .south:
          uvOrigin = textureOffset + Vec2f(baseBoxSize.z * 2 + baseBoxSize.x, baseBoxSize.z)
          uvSize = Vec2f(baseBoxSize.x, baseBoxSize.y)
          verticalAxis = .y
          horizontalAxis = .x
        case .up:
          uvOrigin = textureOffset + Vec2f(baseBoxSize.z, 0)
          uvSize = Vec2f(baseBoxSize.x, baseBoxSize.z)
          verticalAxis = .z
          horizontalAxis = .x
        case .down:
          uvOrigin = textureOffset + Vec2f(baseBoxSize.z + baseBoxSize.x, 0)
          uvSize = Vec2f(baseBoxSize.x, baseBoxSize.z)
          verticalAxis = .z
          horizontalAxis = .x
      }

      if invertedAxes[horizontalAxis.index] {
        uvOrigin.x += uvSize.x
        uvSize.x *= -1
      }
      if invertedAxes[verticalAxis.index] {
        uvOrigin.y += uvSize.y
        uvSize.y *= -1
      }

      let uvs = [
        uvOrigin,
        uvOrigin + Vec2f(0, uvSize.y),
        uvOrigin + Vec2f(uvSize.x, uvSize.y),
        uvOrigin + Vec2f(uvSize.x, 0),
      ].map {
        $0 / Vec2f(Float(texturePalette.palette.width), Float(texturePalette.palette.height))
      }

      let faceVertexPositions = CubeGeometry.faceVertices[direction.rawValue]
      for (uv, vertexPosition) in zip(uvs, faceVertexPositions) {
        var position = vertexPosition * boxSize + boxPosition
        position =
          (Vec4f(position, 1) * transformation * MatrixUtil.rotationMatrix(yaw + .pi, around: .y))
          .xyz
        position /= 16
        position += self.position
        let vertex = EntityVertex(
          x: position.x,
          y: position.y,
          z: position.z,
          r: textureIndex == nil ? color.x : 1,
          g: textureIndex == nil ? color.y : 1,
          b: textureIndex == nil ? color.z : 1,
          u: uv.x,
          v: uv.y,
          textureIndex: textureIndex.map(UInt16.init)
        )
        geometry.vertices.append(vertex)
      }
    }
  }
}
