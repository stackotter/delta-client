import Foundation
import FirebladeECS
import Metal
import MetalKit

/// Renders all entities in the world the client is currently connected to.
public struct EntityRenderer: Renderer {
  /// The color to render hit boxes as. Defaults to 0xe3c28d (light cream colour).
  public var hitBoxColor = RGBColor(hexCode: 0xe3c28d)
  
  /// The render pipeline state for rendering entities. Does not have blending enabled.
  private var renderPipelineState: MTLRenderPipelineState
  /// The buffer containing the uniforms for all rendered entities.
  private var instanceUniformsBuffer: MTLBuffer?
  /// The buffer containing the hit box vertices. They form a basic cube and instanced rendering is used to render the cube once for each entity.
  private var vertexBuffer: MTLBuffer
  /// The buffer containing the index windings for the template hit box (see ``vertexBuffer``.
  private var indexBuffer: MTLBuffer
  /// The number of indices in ``indexBuffer``.
  private var indexCount: Int
  
  /// The client that entities will be renderer for.
  private var client: Client
  /// The device that will be used to render.
  private var device: MTLDevice
  /// The command queue used to perform operations outside of the main render loop.
  private var commandQueue: MTLCommandQueue
  
  /// Creates a new entity renderer.
  public init(client: Client, device: MTLDevice, commandQueue: MTLCommandQueue) throws {
    self.client = client
    self.device = device
    self.commandQueue = commandQueue
    
    // Load library
    let library = try MetalUtil.loadDefaultLibrary(device)
    let vertexFunction = try MetalUtil.loadFunction("entityVertexShader", from: library)
    let fragmentFunction = try MetalUtil.loadFunction("entityFragmentShader", from: library)
    
    // Create render pipeline state
    renderPipelineState = try MetalUtil.makeRenderPipelineState(
      device: device,
      label: "dev.stackotter.delta-client.EntityRenderer",
      vertexFunction: vertexFunction,
      fragmentFunction: fragmentFunction,
      blendingEnabled: false)
    
    // Create hitbox geometry (hitboxes are rendered using instancing)
    var geometry = Self.createHitBoxGeometry(color: hitBoxColor)
    indexCount = geometry.indices.count
    
    vertexBuffer = try MetalUtil.makeBuffer(
      device,
      bytes: &geometry.vertices,
      length: geometry.vertices.count * MemoryLayout<EntityVertex>.stride,
      options: .storageModeShared,
      label: "entityHitBoxVertices")
    
    indexBuffer = try MetalUtil.makeBuffer(
      device,
      bytes: &geometry.indices,
      length: geometry.indices.count * MemoryLayout<UInt32>.stride,
      options: .storageModeShared,
      label: "entityHitBoxIndices")
  }
  
  /// Renders all entity hit boxes using instancing.
  public mutating func render(
    view: MTKView,
    encoder: MTLRenderCommandEncoder,
    commandBuffer: MTLCommandBuffer,
    worldToClipUniformsBuffer: MTLBuffer,
    camera: Camera
  ) throws {
    // Get all renderable entities
    let entities = client.game.nexus.family(requiresAll: EntityPosition.self, EntityHitBox.self, excludesAll: ClientPlayerEntity.self)
    
    guard !entities.isEmpty else {
      return
    }
    
    // Create uniforms for each entity
    var entityUniforms: [Uniforms] = []
    for (position, hitBox) in entities {
      let size = hitBox.size
      var position = SIMD3<Float>(position.smoothVector)
      position -= SIMD3<Float>(hitBox.width, 0, hitBox.width) * 0.5
      
      let uniforms = Uniforms(transformation: MatrixUtil.scalingMatrix(size) * MatrixUtil.translationMatrix(position))
      entityUniforms.append(uniforms)
    }
    
    // Create buffer for instance uniforms. If the current buffer is big enough, use it unless it is more than 64 entities too big.
    // The maximum size limit is imposed so that the buffer isn't too much bigger than necessary. New buffers are always created with
    // room for 32 more entities so that a new buffer isn't created each time an entity is added.
    let minimumBufferSize = entityUniforms.count * MemoryLayout<Uniforms>.stride
    let maximumBufferSize = minimumBufferSize + 64 * MemoryLayout<Uniforms>.stride
    var instanceUniformsBuffer: MTLBuffer
    
    if let buffer = self.instanceUniformsBuffer, buffer.length >= minimumBufferSize, buffer.length <= maximumBufferSize {
      buffer.contents().copyMemory(from: &entityUniforms, byteCount: minimumBufferSize)
      instanceUniformsBuffer = buffer
    } else {
      log.trace("Creating new instance uniforms buffer")
      instanceUniformsBuffer = try MetalUtil.makeBuffer(
        device,
        length: minimumBufferSize + MemoryLayout<Uniforms>.stride * 32,
        options: .storageModeShared,
        label: "entityInstanceUniforms")
      instanceUniformsBuffer.contents().copyMemory(from: &entityUniforms, byteCount: minimumBufferSize)
    }
    
    // A hack to solve https://bugs.swift.org/browse/SR-15613
    // If this isn't done, `entityUniforms` gets freed somewhere around line 99 in release builds
    use(entityUniforms)
    
    self.instanceUniformsBuffer = instanceUniformsBuffer
    
    // Render all the hitboxes using instancing
    encoder.setRenderPipelineState(renderPipelineState)
    encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    encoder.setVertexBuffer(instanceUniformsBuffer, offset: 0, index: 2)
    encoder.drawIndexedPrimitives(type: .triangle, indexCount: indexCount, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: entities.count)
  }
  
  /// A hack used to solve https://bugs.swift.org/browse/SR-15613
  @inline(never)
  @_optimize(none)
  private func use(_ thing: Any) {}
  
  /// Creates a coloured and shaded cube to be rendered using instancing as entities' hitboxes.
  private static func createHitBoxGeometry(color: RGBColor) -> (vertices: [EntityVertex], indices: [UInt32]) {
    var vertices: [EntityVertex] = []
    var indices: [UInt32] = []
    
    for direction in Direction.allDirections {
      let faceVertices = CubeGeometry.faceVertices[direction]
      for position in faceVertices! {
        let color = color.floatVector * CubeGeometry.shades[direction.rawValue]
        vertices.append(
          EntityVertex(
            x: position.x,
            y: position.y,
            z: position.z,
            r: color.x,
            g: color.y,
            b: color.z
          ))
      }
      
      let offset = UInt32(indices.count / 6 * 4)
      for value in CubeGeometry.faceWinding {
        indices.append(value + offset)
      }
    }
    
    return (vertices: vertices, indices: indices)
  }
}
