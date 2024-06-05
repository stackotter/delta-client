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
        into: &geometry
      )
    }

    for (nestedIndex, nestedSubmodel) in (submodel.submodels ?? []).enumerated() {
      buildSubmodel(
        nestedSubmodel,
        index: nestedIndex,
        transformation: transformation,
        into: &geometry
      )
    }
  }

  func buildBox(
    _ box: JSONEntityModel.Box,
    color: Vec3f,
    transformation: Mat4x4f,
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

    for direction in Direction.allDirections {
      // The index of the first vertex of this face
      let offset = UInt32(geometry.vertices.count)
      for index in CubeGeometry.faceWinding {
        geometry.indices.append(index &+ offset)
      }

      let faceVertexPositions = CubeGeometry.faceVertices[direction.rawValue]
      for vertexPosition in faceVertexPositions {
        var position = vertexPosition * boxSize + boxPosition
        position = (Vec4f(position, 1) * transformation).xyz
        position /= 16
        position += self.position
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
