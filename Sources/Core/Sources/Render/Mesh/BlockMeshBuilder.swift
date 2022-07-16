import simd

struct BlockMeshBuilder {
  let model: BlockModel
  let modelToWorld: matrix_float4x4
  let culledFaces: Set<Direction> // TODO: Make bitset based replacement for optimisation
  let lightLevel: LightLevel
  let neighbourLightLevels: [Direction: LightLevel] // TODO: Convert to array for faster access
  let tintColor: SIMD3<Float>
  let blockTexturePalette: TexturePalette // TODO: Remove when texture type is baked into block models

  func build(
    into geometry: inout Geometry,
    translucentGeometry: inout [(size: Float, geometry: Geometry)]
  ) {
    for part in model.parts {
      buildPart(
        part,
        into: &geometry,
        translucentGeometry: &translucentGeometry
      )
    }
  }

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
        let minimum = simd_make_float3(SIMD4<Float>(0, 0, 0, 1) * element.transformation * modelToWorld)
        let maximum = simd_make_float3(SIMD4<Float>(1, 1, 1, 1) * element.transformation * modelToWorld)
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
    transformedBy vertexToWorld: matrix_float4x4,
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
    transformedBy vertexToWorld: matrix_float4x4,
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
    let faceLightLevel = max(faceLightLevel.block, faceLightLevel.sky)
    let faceDirection = face.actualDirection.rawValue
    var shade: Float = 1.0
    if shouldShade {
      shade = CubeGeometry.shades[faceDirection]
    }
    shade *= Float(faceLightLevel) / 15

    // Calculate the tint color to apply to the face
    let tint: SIMD3<Float>
    if face.isTinted {
      tint = tintColor * shade
    } else {
      tint = SIMD3<Float>(repeating: shade)
    }

    let textureIndex = UInt16(face.texture)
    let isTransparent = textureType == .transparent

    // Add vertices to mesh
    for (uvIndex, vertexPosition) in faceVertexPositions.enumerated() {
      let position = simd_make_float3(SIMD4<Float>(vertexPosition, 1) * vertexToWorld)
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
        textureIndex: textureIndex,
        isTransparent: isTransparent
      )
      geometry.vertices.append(vertex)
    }
  }
}
