import CoreFoundation
import DeltaCore
import FirebladeECS
import Foundation

public struct EntityMeshBuilder {
  /// Associates entity kinds with hardcoded entity texture identifiers. Used to manually
  /// instruct Delta Client where to find certain textures that aren't in the standard
  /// locations.
  public static let hardcodedTextureIdentifiers: [Identifier: Identifier] = [
    Identifier(name: "player"): Identifier(name: "entity/steve"),
    Identifier(name: "dragon"): Identifier(name: "entity/enderdragon/dragon"),
    Identifier(name: "chest"): Identifier(name: "entity/chest/normal"),
  ]

  public let entity: Entity
  public let entityKind: Identifier
  public let position: Vec3f
  public let pitch: Float
  public let yaw: Float
  public let entityModelPalette: EntityModelPalette
  public let itemModelPalette: ItemModelPalette
  public let blockModelPalette: BlockModelPalette
  public let entityTexturePalette: MetalTexturePalette
  public let blockTexturePalette: MetalTexturePalette
  public let hitbox: AxisAlignedBoundingBox

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

  // TODO: Propagate all warnings as errors and then handle them and emit them as warnings in EntityRenderer instead
  /// `blockGeometry` and `translucentBlockGeometry` are used to render block entities and block item entities.
  func build(
    into geometry: inout Geometry<EntityVertex>,
    blockGeometry: inout Geometry<BlockVertex>,
    translucentBlockGeometry: inout SortableMesh
  ) {
    if let model = entityModelPalette.models[entityKind] {
      buildModel(model, into: &geometry)
    } else if let itemMetadata = entity.get(component: EntityMetadata.self)?.itemMetadata,
      let itemStack = itemMetadata.slot.stack,
      let itemModel = itemModelPalette.model(for: itemStack.itemId)
    {
      // TODO: Figure out why these bobbing constants and hardcoded translations are so weird
      //   (they're even still slightly off vanilla, there must be a different order of transformations
      //   that makes these numbers nice or something).
      let time = CFAbsoluteTimeGetCurrent() * TickScheduler.defaultTicksPerSecond
      let phaseOffset = Double(itemMetadata.bobbingPhaseOffset)
      let verticalOffset = Float(Foundation.sin(time / 10 + phaseOffset)) / 8 * 3
      let spinAngle = -Float((time / 20 + phaseOffset).remainder(dividingBy: 2 * .pi))
      let bob =
        MatrixUtil.translationMatrix(Vec3f(0, verticalOffset, 0))
        * MatrixUtil.rotationMatrix(y: spinAngle)

      switch itemModel {
        case let .entity(identifier, transforms):
          // Remove identifier prefix (entity model palette doesn't have any `item/` or `entity/` prefixes).
          var entityIdentifier = identifier
          entityIdentifier.name = entityIdentifier.name.replacingOccurrences(of: "item/", with: "")

          guard let entityModel = entityModelPalette.models[entityIdentifier] else {
            log.warning("Missing entity model for entity with '\(entityIdentifier)' (as item)")
            return
          }

          let transformation =
            bob * transforms.ground * MatrixUtil.translationMatrix(Vec3f(0, 11.0 / 64, 0))
          buildModel(
            entityModel,
            textureIdentifier: entityIdentifier,
            transformation: transformation,
            into: &geometry
          )
        case let .blockModel(id):
          guard let blockModel = blockModelPalette.model(for: id, at: nil) else {
            log.warning(
              "Missing block model for item entity (block id: \(id), item id: \(itemStack.itemId))"
            )
            return
          }

          // TODO: Don't just use dummy lighting
          var neighbourLightLevels: [Direction: LightLevel] = [:]
          for direction in Direction.allDirections {
            neighbourLightLevels[direction] = LightLevel(sky: 15, block: 0)
          }

          let transformation =
            MatrixUtil.translationMatrix(Vec3f(-0.5, 0, -0.5))
            * bob
            * MatrixUtil.scalingMatrix(0.25)
            * MatrixUtil.translationMatrix(Vec3f(0, 7.0 / 32.0, 0))
            * MatrixUtil.rotationMatrix(y: yaw + .pi)
            * MatrixUtil.translationMatrix(position)
          let builder = BlockMeshBuilder(
            model: blockModel,
            position: .zero,
            modelToWorld: transformation,
            culledFaces: [],
            lightLevel: LightLevel(sky: 15, block: 0),
            neighbourLightLevels: [:],
            tintColor: Vec3f(1, 1, 1),
            blockTexturePalette: blockTexturePalette.palette
          )
          var translucentElement = SortableMeshElement()
          builder.build(into: &blockGeometry, translucentGeometry: &translucentElement)
          translucentBlockGeometry.add(translucentElement)
        case .layered:
          buildAABB(hitbox, into: &geometry)
        case .empty:
          break
      }
    } else {
      buildAABB(hitbox, into: &geometry)
    }

    if let dragonParts = entity.get(component: EnderDragonParts.self) {
      for part in dragonParts.parts {
        let aabb = part.aabb(withParentPosition: Vec3d(position))
        buildAABB(aabb, into: &geometry)
      }
    }
  }

  func buildAABB(_ aabb: AxisAlignedBoundingBox, into geometry: inout Geometry<EntityVertex>) {
    let transformation =
      MatrixUtil.scalingMatrix(Vec3f(aabb.size))
      * MatrixUtil.translationMatrix(Vec3f(aabb.position))
    for direction in Direction.allDirections {
      let offset = UInt32(geometry.vertices.count)
      for index in CubeGeometry.faceWinding {
        geometry.indices.append(index &+ offset)
      }

      let faceVertexPositions = CubeGeometry.faceVertices[direction.rawValue]
      for vertexPosition in faceVertexPositions {
        let position = (Vec4f(vertexPosition, 1) * transformation).xyz
        let color = EntityRenderer.hitBoxColor.floatVector
        let vertex = EntityVertex(
          x: position.x,
          y: position.y,
          z: position.z,
          r: color.x,
          g: color.y,
          b: color.z,
          u: 0,
          v: 0,
          textureIndex: nil
        )
        geometry.vertices.append(vertex)
      }
    }
  }

  /// The unit of `transformation` is blocks.
  func buildModel(
    _ model: JSONEntityModel,
    textureIdentifier: Identifier? = nil,
    transformation: Mat4x4f = MatrixUtil.identity,
    into geometry: inout Geometry<EntityVertex>
  ) {
    let baseTextureIdentifier = textureIdentifier ?? entityKind
    let texture: Int?
    if let identifier = Self.hardcodedTextureIdentifiers[baseTextureIdentifier] {
      texture = entityTexturePalette.textureIndex(for: identifier)
    } else {
      // Entity textures can be in all sorts of structures so we just have a few
      // educated guesses for now.
      let textureIdentifier = Identifier(
        namespace: baseTextureIdentifier.namespace,
        name: "entity/\(baseTextureIdentifier.name)"
      )
      let nestedTextureIdentifier = Identifier(
        namespace: baseTextureIdentifier.namespace,
        name: "entity/\(baseTextureIdentifier.name)/\(baseTextureIdentifier.name)"
      )
      texture =
        entityTexturePalette.textureIndex(for: textureIdentifier)
        ?? entityTexturePalette.textureIndex(for: nestedTextureIdentifier)
    }

    for (index, submodel) in model.models.enumerated() {
      buildSubmodel(
        submodel,
        index: index,
        textureIndex: texture,
        transformation: transformation,
        into: &geometry
      )
    }
  }

  /// The unit of `transformation` is blocks.
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
        * MatrixUtil.translationMatrix(translation / 16)
        * transformation
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

  /// The unit of `transformation` is 16 units per block.
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

      let textureSize = Vec2f(
        Float(entityTexturePalette.palette.width),
        Float(entityTexturePalette.palette.height)
      )
      let uvs = [
        uvOrigin,
        uvOrigin + Vec2f(0, uvSize.y),
        uvOrigin + Vec2f(uvSize.x, uvSize.y),
        uvOrigin + Vec2f(uvSize.x, 0),
      ].map { pixelUV in
        pixelUV / textureSize
      }

      let faceVertexPositions = CubeGeometry.faceVertices[direction.rawValue]
      for (uv, vertexPosition) in zip(uvs, faceVertexPositions) {
        var position = vertexPosition * boxSize + boxPosition
        position /= 16
        position =
          (Vec4f(position, 1) * transformation * MatrixUtil.rotationMatrix(y: yaw + .pi))
          .xyz
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
