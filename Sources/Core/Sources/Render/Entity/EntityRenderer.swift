import Foundation
import FirebladeECS
import Metal
import MetalKit

public class EntityRenderer {
  public static let hitBoxColor = RGBColor(hexCode: 0xe3c28d)
  
  private var renderPipelineState: MTLRenderPipelineState
  private var vertexBuffer: MTLBuffer
  private var indexBuffer: MTLBuffer
  private var indexCount: Int
  
  private var instanceUniformsBuffer: MTLBuffer?
  
  public init(_ device: MTLDevice, _ commandQueue: MTLCommandQueue) throws {
    log.info("Loading entity shaders")
    // Load library
    guard let bundle = Bundle(url: Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/DeltaCore_DeltaCore.bundle")) else {
      throw RenderError.failedToGetBundle
    }
    
    guard let libraryURL = bundle.url(forResource: "default", withExtension: "metallib") else {
      throw RenderError.failedToLocateMetallib
    }
    
    let library: MTLLibrary
    do {
      library = try device.makeLibrary(URL: libraryURL)
    } catch {
      throw RenderError.failedToCreateMetallib(error)
    }
    
    // Load shaders
    guard
      let vertex = library.makeFunction(name: "entityVertexShader"),
      let fragment = library.makeFunction(name: "entityFragmentShader")
    else {
      log.critical("Failed to load entity shaders")
      throw RenderError.failedToLoadShaders
    }
    
    // Create render pipeline state
    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.label = "dev.stackotter.delta-client.EntityRenderer"
    pipelineStateDescriptor.vertexFunction = vertex
    pipelineStateDescriptor.fragmentFunction = fragment
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float
    
    let pipelineState: MTLRenderPipelineState
    do {
      pipelineState = try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    } catch {
      log.critical("Failed to create render pipeline state: \(error)")
      throw RenderError.failedToCreateEntityRenderPipelineState(error)
    }
    
    self.renderPipelineState = pipelineState
    
    // Create hitbox geometry (hitboxes are rendered using instancing)
    var geometry = Self.createHitBoxGeometry(color: Self.hitBoxColor)
    
    guard
      let vertexBuffer = device.makeBuffer(bytes: &geometry.vertices, length: geometry.vertices.count * MemoryLayout<BlockVertex>.stride, options: .storageModeShared),
      let indexBuffer = device.makeBuffer(bytes: &geometry.indices, length: geometry.indices.count * MemoryLayout<UInt32>.stride, options: .storageModeShared)
    else {
      log.error("Failed to create vertex and index buffers for entity renderer")
      throw RenderError.failedToCreateEntityGeometryBuffers
    }
    
    self.vertexBuffer = vertexBuffer
    self.indexBuffer = indexBuffer
    indexCount = geometry.indices.count
  }
  
  /// Renders all entity hitboxes using instancing.
  public func renderHitBoxes(_ view: MTKView, uniformsBuffer: MTLBuffer, camera: Camera, nexus: Nexus, device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
    // Get all renderable entities
    let entities = nexus.family(requiresAll: EntityPosition.self, EntityHitBox.self, excludesAll: ClientPlayerEntity.self)
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
      guard let buffer = device.makeBuffer(length: minimumBufferSize + MemoryLayout<Uniforms>.stride * 32, options: .storageModeShared) else {
        log.warning("Failed to create new instance uniforms buffer")
        return
      }
      buffer.contents().copyMemory(from: &entityUniforms, byteCount: minimumBufferSize)
      instanceUniformsBuffer = buffer
      self.instanceUniformsBuffer = instanceUniformsBuffer
    }
    
    // Render all the hitboxes using instancing
    renderEncoder.setRenderPipelineState(renderPipelineState)
    renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
    renderEncoder.setVertexBuffer(instanceUniformsBuffer, offset: 0, index: 2)
    renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexCount, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: entities.count)
  }
  
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
