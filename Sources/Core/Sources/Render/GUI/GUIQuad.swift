import Metal

enum GUIQuadGeometry {
  static var vertices: [GUIQuadVertex] = [
    GUIQuadVertex(position: [0, 0], uv: [0, 0]),
    GUIQuadVertex(position: [1, 0], uv: [1, 0]),
    GUIQuadVertex(position: [1, 1], uv: [1, 1]),
    GUIQuadVertex(position: [0, 1], uv: [0, 1])
  ]

  static var indices: [UInt16] = [
    0, 1, 2,
    2, 3, 0
  ]

  public static func getVertexBuffer(device: MTLDevice) throws -> any MTLBuffer {
    return try MetalUtil.makeBuffer(
      device,
      bytes: &vertices,
      length: MemoryLayout<GUIQuadVertex>.stride * vertices.count,
      options: [],
      label: "GUIQuad.vertices"
    )
  }

  public static func getIndexBuffer(device: MTLDevice) throws -> any MTLBuffer {
    return try MetalUtil.makeBuffer(
      device,
      bytes: &indices,
      length: MemoryLayout<UInt16>.stride * indices.count,
      options: [],
      label: "GUIQuad.indices"
    )
  }
}
