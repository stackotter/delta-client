//
//  WorldRenderer.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import MetalKit


enum WorldRendererError: LocalizedError {
  case failedToCreateUniformBuffer
}

class WorldRenderer {
  var pipelineState: MTLRenderPipelineState
  var depthState: MTLDepthStencilState
  
  var blockArrayTexture: MTLTexture
  
  var client: Client
  
  let nearDistance = 0.0001
  let farDistance = 1000
  var camera: Camera
  
  var world: World?
  var chunkPreparer: ChunkPreparer
  
  init(client: Client) {
    Logger.info("initialising world renderer")
    
    // get metal device
    guard let metalDevice = MTLCreateSystemDefaultDevice() else {
      Logger.error("no metal device found")
      fatalError("no metal device found")
    }
    
    // load shaders
    Logger.info("loading shaders")
    guard
      let defaultLibrary = metalDevice.makeDefaultLibrary(),
      let vertex = defaultLibrary.makeFunction(name: "chunkVertexShader"),
      let fragment = defaultLibrary.makeFunction(name: "chunkFragmentShader")
    else {
      Logger.error("failed to load shaders")
      fatalError("failed to load world shaders")
    }
    
    // create pipeline descriptor
    Logger.info("creating pipeline descriptor")
    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.label = "Triangle Pipeline"
    pipelineStateDescriptor.vertexFunction = vertex
    pipelineStateDescriptor.fragmentFunction = fragment
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float
    
    // create pipeline state
    Logger.info("creating pipeline state")
    do {
      pipelineState = try metalDevice.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    } catch {
      fatalError("failed to create render pipeline state")
    }
    
    // setup depth texture settings
    let depthDescriptor = MTLDepthStencilDescriptor()
    depthDescriptor.depthCompareFunction = .lessEqual
    depthDescriptor.isDepthWriteEnabled = true
    
    guard let depthState = metalDevice.makeDepthStencilState(descriptor: depthDescriptor) else {
      Logger.error("failed to create depth stencil state")
      fatalError("failed to create depth stencil state")
    }
    self.depthState = depthState
    
    Logger.info("loading textures")
    blockArrayTexture = client.managers.textureManager.createArrayTexture(metalDevice: metalDevice)
    
    // setup camera
    let fovDegrees: Float = 90
    let fovRadians = fovDegrees / 180 * Float.pi
    camera = Camera()
    camera.fovY = fovRadians
    
    // TODO: remove need for this fatal error
    guard let world = client.server.world else {
      fatalError("no world supplied to world renderer")
    }
    self.chunkPreparer = ChunkPreparer(world: world, camera: camera)
    
    self.client = client
    
    Logger.info("initialised renderer")
  }
  
  func createWorldUniforms() -> WorldUniforms {
    return WorldUniforms(worldToClipSpace: camera.getWorldToClipMatrix())
  }
  
  func createWorldUniformBuffer(from uniforms: WorldUniforms, for device: MTLDevice) throws -> MTLBuffer! {
    var uniforms = uniforms // create mutable copy
    guard let uniformBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<WorldUniforms>.stride, options: []) else {
      throw WorldRendererError.failedToCreateUniformBuffer
    }
    uniformBuffer.label = "worldUniformBuffer"
    return uniformBuffer
  }
  
  func draw(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder, aspect: Float) {
    // update camera parameters
    camera.aspect = aspect
    camera.position = client.server.player.getEyePositon().vector
    camera.setRotation(playerLook: client.server.player.look)
    
    // update chunk preparer
    chunkPreparer.setCamera(camera)
    chunkPreparer.prepareChunks()
    
    // get chunks to render
    var chunks: [Chunk] = []
    let chunkPositions = chunkPreparer.getChunksToRender()
    for chunkPosition in chunkPositions {
      if let chunk = client.server.world?.chunks[chunkPosition] {
        if !chunk.mesh.isEmpty {
          chunks.append(chunk)
        }
      }
    }
    
    // encode draw instructions
    renderEncoder.setRenderPipelineState(pipelineState)
    renderEncoder.setDepthStencilState(depthState)
    renderEncoder.setFrontFacing(.clockwise)
    renderEncoder.setCullMode(.back)
    
    renderEncoder.setFragmentTexture(blockArrayTexture, index: 0)
    
    if Constants.renderMode == .wireframe {
      renderEncoder.setTriangleFillMode(.lines)
      renderEncoder.setCullMode(.none)
    }
    
    // set uniforms
    let worldUniforms = createWorldUniforms()
    guard let worldUniformBuffer = try? createWorldUniformBuffer(from: worldUniforms, for: device) else {
      Logger.error("failed to create world uniform buffer")
      return
    }
    renderEncoder.setVertexBuffer(worldUniformBuffer, offset: 0, index: 1)
    
    // render chunks
    for chunk in chunks where !chunk.mesh.isEmpty {
      if let buffers = try? chunk.mesh.createBuffers(device: device) {
        renderEncoder.setVertexBuffer(buffers.vertexBuffer, offset: 0, index: 0) // set vertices
        renderEncoder.setVertexBuffer(buffers.uniformBuffer, offset: 0, index: 2) // set chunk specific uniforms
        renderEncoder.drawIndexedPrimitives(
          type: .triangle,
          indexCount: buffers.indexBuffer.length / 4,
          indexType: .uint32,
          indexBuffer: buffers.indexBuffer,
          indexBufferOffset: 0)
      } else {
        Logger.error("failed to prepare buffers for chunk at \(chunk.position.chunkX),\(chunk.position.chunkZ)")
      }
    }
  }
}

extension WorldRenderer {
  enum RenderMode {
    case normal
    case wireframe
  }
  
  enum Constants {
    static let renderMode = RenderMode.normal
  }
}
