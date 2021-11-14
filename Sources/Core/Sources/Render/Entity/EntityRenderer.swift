import Foundation
import FirebladeECS
import Metal
import MetalKit

public class EntityRenderer {
  public static let hitBoxColor = RGBColor(hexCode: 0xe3c28d)
  
  public var renderPipelineState: MTLRenderPipelineState
  public var depthState: MTLDepthStencilState
  
  public var vertexBuffer: MTLBuffer
  public var indexBuffer: MTLBuffer
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
    let entities = nexus.family(requiresAll: Box<EntityPosition>.self, Box<EntityKindId>.self, excludesAll: Box<ClientPlayerEntity>.self)
    guard !entities.isEmpty else {
      return
    }
    
    // Create uniforms for each entity
    var entityUniforms: [Uniforms] = []
    for (position, kindId) in entities {
      if let kind = Registry.shared.entityRegistry.entity(withId: kindId.value.id) {
        let size = SIMD3<Float>(kind.width, kind.height, kind.width)
        var position = position.value.vector
        position -= SIMD3<Float>(kind.width, 0, kind.width) * 0.5
        
        let uniforms = Uniforms(transformation: MatrixUtil.scalingMatrix(size) * MatrixUtil.translationMatrix(position))
        entityUniforms.append(uniforms)
      }
      // TODO: make hitbox dimensions a component
    }
    
    // Create uniforms buffer for each entity
    let instanceUniformsBuffer = device.makeBuffer(bytes: &entityUniforms, length: entityUniforms.count * MemoryLayout<Uniforms>.stride, options: .storageModeShared)
    
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
