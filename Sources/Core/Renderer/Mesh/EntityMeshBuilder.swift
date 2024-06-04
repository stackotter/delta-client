import DeltaCore

public struct EntityMeshBuilder {
  let model: JSONEntityModel
  let position: Vec3f

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
    for (index, submodel) in model.models.enumerated() {
      buildSubmodel(submodel, index: index, into: &geometry)
    }
  }

  func buildSubmodel(
    _ submodel: JSONEntityModel.Submodel,
    index: Int,
    into geometry: inout Geometry<EntityVertex>
  ) {
    for box in submodel.boxes ?? [] {
      buildBox(
        box,
        color: index < Self.colors.count ? Self.colors[index] : [0.5, 0.5, 0.5],
        into: &geometry
      )
    }

    for (nestedIndex, nestedSubmodel) in (submodel.submodels ?? []).enumerated() {
      buildSubmodel(nestedSubmodel, index: nestedIndex, into: &geometry)
    }
  }

  func buildBox(
    _ box: JSONEntityModel.Box,
    color: Vec3f,
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

    if let additionalSize = box.sizeAdd {
      let growth = Vec3f(repeating: additionalSize)
      boxPosition -= growth
      boxSize += 2 * growth
    }

    boxPosition = boxPosition / 16 + position
    boxSize /= 16
    for direction in Direction.allDirections {
      // The index of the first vertex of this face
      let offset = UInt32(geometry.vertices.count)
      for index in CubeGeometry.faceWinding {
        geometry.indices.append(index &+ offset)
      }

      let faceVertexPositions = CubeGeometry.faceVertices[direction.rawValue]
      for vertexPosition in faceVertexPositions {
        let position = vertexPosition * boxSize + boxPosition
        let vertex = EntityVertex(
          x: position.x,
          y: position.y,
          z: position.z,
          r: color.x,
          g: color.y,
          b: color.z
        )
        geometry.vertices.append(vertex)
      }
    }
  }
}
