import FirebladeMath
import DeltaCore

/// Builds the mesh for a single block.
struct BlockMeshBuilder {
  let model: BlockModel
  let position: BlockPosition
  let modelToWorld: Mat4x4f
  let culledFaces: DirectionSet
  let lightLevel: LightLevel
  let neighbourLightLevels: [Direction: LightLevel] // TODO: Convert to array for faster access
  let tintColor: Vec3f
  let blockTexturePalette: TexturePalette // TODO: Remove when texture type is baked into block models

  func build(
    into geometry: inout Geometry,
    translucentGeometry: inout SortableMeshElement
  ) {
    var translucentGeometryParts: [(size: Float, geometry: Geometry)] = []
    for part in model.parts {
      buildPart(
        part,
        into: &geometry,
        translucentGeometry: &translucentGeometryParts
      )
    }

    translucentGeometry = Self.mergeTranslucentGeometry(
      translucentGeometryParts,
      position: position
    ) }

  func buildPart(
    _ part: BlockModelPart,
    into geometry: inout Geometry,
    translucentGeometry: inout [(size: Float, geometry: Geometry)]
  ) {
    for element in part.elements {
      var elementTranslucentGeometry = Geometry()
      buildElement(
        element,
        into: &geometry,
        translucentGeometry: &elementTranslucentGeometry
      )

      if !elementTranslucentGeometry.isEmpty {
        // Calculate a size used for sorting nested translucent elements (required for blocks such
        // as honey blocks and slime blocks).
        let minimum = (Vec4f(0, 0, 0, 1) * element.transformation * modelToWorld).xyz
        let maximum = (Vec4f(1, 1, 1, 1) * element.transformation * modelToWorld).xyz
        let size = (maximum - minimum).magnitude
        translucentGeometry.append((size: size, geometry: elementTranslucentGeometry))
      }
    }
  }

  func buildElement(
    _ element: BlockModelElement,
    into geometry: inout Geometry,
    translucentGeometry: inout Geometry
  ) {
    let vertexToWorld = element.transformation * modelToWorld
    for face in element.faces {
      if let cullface = face.cullface, culledFaces.contains(cullface) {
        continue
      }

      let faceLightLevel = LightLevel.max(
        neighbourLightLevels[face.actualDirection] ?? LightLevel(),
        lightLevel
      )

      buildFace(
        face,
        transformedBy: vertexToWorld,
        into: &geometry,
        translucentGeometry: &translucentGeometry,
        faceLightLevel: faceLightLevel,
        shouldShade: element.shade
      )
    }
  }

  func buildFace(
    _ face: BlockModelFace,
    transformedBy vertexToWorld: Mat4x4f,
    into geometry: inout Geometry,
    translucentGeometry: inout Geometry,
    faceLightLevel: LightLevel,
    shouldShade: Bool
  ) {
    // TODO: Bake texture type into block model
    let textureType = blockTexturePalette.textures[face.texture].type
    if textureType == .translucent {
      buildFace(
        face,
        transformedBy: vertexToWorld,
        into: &translucentGeometry,
        faceLightLevel: faceLightLevel,
        shouldShade: shouldShade,
        textureType: textureType
      )
    } else {
      buildFace(
        face,
        transformedBy: vertexToWorld,
        into: &geometry,
        faceLightLevel: faceLightLevel,
        shouldShade: shouldShade,
        textureType: textureType
      )
    }
  }

  func buildFace(
    _ face: BlockModelFace,
    transformedBy vertexToWorld: Mat4x4f,
    into geometry: inout Geometry,
    faceLightLevel: LightLevel,
    shouldShade: Bool,
    textureType: TextureType
  ) {
    // Add face winding
    let offset = UInt32(geometry.vertices.count) // The index of the first vertex of this face
    for index in CubeGeometry.faceWinding {
      geometry.indices.append(index &+ offset)
    }

    let faceVertexPositions = CubeGeometry.faceVertices[face.direction.rawValue]

    // Calculate shade of face
    let faceDirection = face.actualDirection.rawValue
    let shade = shouldShade ? CubeGeometry.shades[faceDirection] : 1

    // Calculate the tint color to apply to the face
    let tint: Vec3f
    if face.isTinted {
      tint = tintColor * shade
    } else {
      tint = Vec3f(repeating: shade)
    }

    let textureIndex = UInt16(face.texture)
    let isTransparent = textureType == .transparent

    // Add vertices to mesh
    for (uvIndex, vertexPosition) in faceVertexPositions.enumerated() {
      let position = (Vec4f(vertexPosition, 1) * vertexToWorld).xyz
      let uv = face.uvs[uvIndex]
      let vertex = BlockVertex(
        x: position.x,
        y: position.y,
        z: position.z,
        u: uv.x,
        v: uv.y,
        r: tint.x,
        g: tint.y,
        b: tint.z,
        a: 1,
        skyLightLevel: UInt8(faceLightLevel.sky),
        blockLightLevel: UInt8(faceLightLevel.block),
        textureIndex: textureIndex,
        isTransparent: isTransparent
      )
      geometry.vertices.append(vertex)
    }
  }

  /// Sort the geometry assuming that smaller translucent elements are always inside of bigger
  /// elements in the same block (e.g. honey block, slime block). The geometry is then combined
  /// into a single element to add to the final mesh to reduce sorting calculations while
  /// rendering.
  private static func mergeTranslucentGeometry(
    _ geometries: [(size: Float, geometry: Geometry)],
    position: BlockPosition
  ) -> SortableMeshElement {
    var geometries = geometries // TODO: This may cause an unnecessary copy
    geometries.sort { first, second in
      return second.size > first.size
    }

    // Counts used to reserve a suitable amount of capacity
    var vertexCount = 0
    var indexCount = 0
    for (_, geometry) in geometries {
      vertexCount += geometry.vertices.count
      indexCount += geometry.indices.count
    }

    var vertices: [BlockVertex] = []
    var indices: [UInt32] = []
    vertices.reserveCapacity(vertexCount)
    indices.reserveCapacity(indexCount)

    for (_, geometry) in geometries {
      let startingIndex = UInt32(vertices.count)
      vertices.append(contentsOf: geometry.vertices)
      indices.append(contentsOf: geometry.indices.map { index in
        return index + startingIndex
      })
    }

    let geometry = Geometry(vertices: vertices, indices: indices)
    return SortableMeshElement(
      geometry: geometry,
      centerPosition: position.floatVector + Vec3f(0.5, 0.5, 0.5)
    )
  }
}
