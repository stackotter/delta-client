import Foundation
import FirebladeECS
import Metal
import MetalKit

public class EntityRenderer {
  public var renderPipelineState: MTLRenderPipelineState
  public var depthState: MTLDepthStencilState
  
  public var vertexBuffer: MTLBuffer
  public var indexBuffer: MTLBuffer
  public var uniformsBuffer: MTLBuffer
  public var indexCount: Int
  
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
    
    // Create depth stencil state
    let depthDescriptor = MTLDepthStencilDescriptor()
    depthDescriptor.depthCompareFunction = .lessEqual
    depthDescriptor.isDepthWriteEnabled = true
    
    guard let depthState = device.makeDepthStencilState(descriptor: depthDescriptor) else {
      log.critical("Failed to create depth stencil state")
      throw RenderError.failedToCreateEntityDepthStencilState
    }
    
    self.depthState = depthState
    
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
    
    // Create hitbox geometry (hitboxes are rendered using instancing).
    var vertices: [EntityVertex] = []
    for position in CubeGeometry.cubeVertices {
      vertices.append(
        EntityVertex(
          x: position.x,
          y: position.y,
          z: position.z,
          r: 1,
          g: 0,
          b: 0
        ))
    }
    
    let faceVertices: [[UInt32]] = [
      [3, 7, 4, 0],
      [6, 2, 1, 5],
      [3, 2, 6, 7],
      [4, 5, 1, 0],
      [0, 1, 2, 3],
      [7, 6, 5, 4]]
    
    var indices: [UInt32] = []
    for vertexIndices in faceVertices {
      for index in CubeGeometry.faceWinding {
        indices.append(vertexIndices[Int(index)])
      }
    }
    
    var uniforms = Uniforms()
    
    guard
      let vertexBuffer = device.makeBuffer(bytes: &vertices, length: vertices.count * MemoryLayout<BlockVertex>.stride, options: .storageModeShared),
      let indexBuffer = device.makeBuffer(bytes: &indices, length: indices.count * MemoryLayout<UInt32>.stride, options: .storageModeShared),
      let uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<Uniforms>.stride, options: .storageModeShared)
    else {
      log.error("Failed to create vertex and index buffers for entity renderer")
      throw RenderError.failedToCreateEntityGeometryBuffers
    }
    
    self.vertexBuffer = vertexBuffer
    self.indexBuffer = indexBuffer
    self.uniformsBuffer = uniformsBuffer
    indexCount = indices.count
  }
  
  public func render(_ view: MTKView, camera: Camera, nexus: Nexus, device: MTLDevice, commandBuffer: MTLCommandBuffer, commandQueue: MTLCommandQueue) {
    let entities = nexus.family(requiresAll: Box<EntityPosition>.self, Box<EntityKindId>.self, excludesAll: Box<ClientPlayerEntity>.self)
    guard !entities.isEmpty else {
      return
    }
    
    var entityUniforms: [Uniforms] = []
    for (position, kindId) in entities {
      if let kind = Registry.shared.entityRegistry.entity(withId: kindId.value.id) {
        log.debug("Kind id: \(kindId.value.id), identifier: \(kind.identifier)")
        
        let size = SIMD3<Float>(kind.width, kind.height, kind.width)
        let position = position.value.vector
        
        let uniforms = Uniforms(transformation: MatrixUtil.scalingMatrix(size) * MatrixUtil.translationMatrix(position))
        entityUniforms.append(uniforms)
      }
      // TODO: make hitbox dimensions a component
    }
    
    guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
      log.error("Failed to get current render pass descriptor")
      return
    }
    
    renderPassDescriptor.colorAttachments[0].loadAction = .load
    renderPassDescriptor.depthAttachment.loadAction = .load
    
    guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
      log.error("Failed to create entity render encoder")
      return
    }
    
    var uniforms = Uniforms(transformation: camera.getFrustum().worldToClip)
    uniformsBuffer.contents().copyMemory(from: &uniforms, byteCount: MemoryLayout<Uniforms>.stride)
    
    let instanceUniformsBuffer = device.makeBuffer(bytes: &entityUniforms, length: entityUniforms.count * MemoryLayout<Uniforms>.stride, options: .storageModeShared)
    
    encoder.setRenderPipelineState(renderPipelineState)
    encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    encoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
    encoder.setVertexBuffer(instanceUniformsBuffer, offset: 0, index: 2)
    encoder.drawIndexedPrimitives(type: .triangle, indexCount: indexCount, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: entities.count)
    encoder.endEncoding()
  }
}
