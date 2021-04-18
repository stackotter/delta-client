//
//  WorldRenderer.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import MetalKit
import os

class WorldRenderer {
  var metalCommandQueue: MTLCommandQueue
  var pipelineState: MTLRenderPipelineState
  var depthState: MTLDepthStencilState
  
  var blockArrayTexture: MTLTexture
  
  var client: Client
  var managers: Managers
  
  let nearDistance = 0.0001
  let farDistance = 1000
  var camera: Camera
  
  var world: World?
  var chunkPreparer: ChunkPreparer
  
  init(client: Client) {
    guard let metalDevice = MTLCreateSystemDefaultDevice() else {
      fatalError("no metal device found")
    }
    
    self.client = client
    self.managers = client.managers
    
    let fovDegrees: Float = 90
    let fovRadians = fovDegrees / 180 * Float.pi
    camera = Camera()
    camera.fovY = fovRadians
    
    Logger.debug("creating command queue")
    self.metalCommandQueue = metalDevice.makeCommandQueue()!
    
    Logger.debug("loading shaders")
    let defaultLibrary = metalDevice.makeDefaultLibrary()
    let vertex = defaultLibrary!.makeFunction(name: "chunkVertexShader")
    let fragment = defaultLibrary!.makeFunction(name: "chunkFragmentShader")
    
    Logger.debug("creating pipeline descriptor")
    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.label = "Triangle Pipeline"
    pipelineStateDescriptor.vertexFunction = vertex!
    pipelineStateDescriptor.fragmentFunction = fragment!
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float
    
    let depthDescriptor = MTLDepthStencilDescriptor()
    depthDescriptor.depthCompareFunction = .lessEqual
    depthDescriptor.isDepthWriteEnabled = true
    depthState = metalDevice.makeDepthStencilState(descriptor: depthDescriptor)!
    
    Logger.debug("creating pipeline state")
    pipelineState = try! metalDevice.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    
    Logger.debug("loading textures")
    blockArrayTexture = managers.textureManager.createArrayTexture(metalDevice: metalDevice)
    
    Logger.debug("initialised renderer")
    
    self.chunkPreparer = ChunkPreparer(world: client.server.world!, camera: camera)
  }
  
  func createWorldUniforms() -> WorldUniforms {
    return WorldUniforms(worldToClipSpace: camera.getWorldToClipMatrix())
  }
  
  func createWorldUniformBuffer(from uniforms: WorldUniforms, for device: MTLDevice) -> MTLBuffer! {
    var uniforms = uniforms // create mutable copy
    let uniformBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<WorldUniforms>.stride, options: [])!
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
    let worldUniformBuffer = createWorldUniformBuffer(from: worldUniforms, for: device)
    renderEncoder.setVertexBuffer(worldUniformBuffer, offset: 0, index: 1)
    
    // render chunks
    for chunk in chunks {
      if !chunk.mesh.isEmpty {
        let buffers = chunk.mesh.createBuffers(device: device)
        
        renderEncoder.setVertexBuffer(buffers.vertexBuffer, offset: 0, index: 0) // set vertices
        renderEncoder.setVertexBuffer(buffers.uniformBuffer, offset: 0, index: 2) // set chunk specific uniforms
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: buffers.indexBuffer.length/4, indexType: .uint32, indexBuffer: buffers.indexBuffer, indexBufferOffset: 0)
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
