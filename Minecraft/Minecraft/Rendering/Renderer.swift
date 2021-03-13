//
//  Renderer.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import MetalKit
import os

class Renderer {
  var logger: Logger
  
  var metalDevice: MTLDevice
  var metalCommandQueue: MTLCommandQueue
  var pipelineState: MTLRenderPipelineState
  var depthState: MTLDepthStencilState
  
  var texture: MTLTexture
  
  var client: Client
  var managers: Managers
  
  init(device: MTLDevice, client: Client) {
    self.metalDevice = device
    self.client = client
    self.managers = client.managers
    
    Logger.debug("creating command queue")
    self.metalCommandQueue = metalDevice.makeCommandQueue()!
    
    Logger.debug("loading shaders")
    let defaultLibrary = metalDevice.makeDefaultLibrary()
    let vertex = defaultLibrary!.makeFunction(name: "vertexShader")
    let fragment = defaultLibrary!.makeFunction(name: "fragmentShader")
    
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
    depthState = device.makeDepthStencilState(descriptor: depthDescriptor)!
    
    Logger.debug("creating pipeline state")
    pipelineState = try! self.metalDevice.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    
    Logger.debug("loading textures")
    let textureURL = managers.storageManager.getAssetsFolder().appendingPathComponent("minecraft/textures/block/chiseled_stone_bricks.png") // TODO: create texture manager
    let textureLoader = MTKTextureLoader(device: self.metalDevice)
    texture = try! textureLoader.newTexture(URL: textureURL)
    
    Logger.debug("initialised renderer")
    
    self.logger = Logger(for: type(of: self))
  }
  
  func createWorldToClipSpaceMatrix(aspect: Float) -> MTLBuffer {
    let chunkPosition = client.server.player.chunkPosition
    var playerRelativePosition = client.server.player.position
    playerRelativePosition.x -= Double(chunkPosition.chunkX*16)
    playerRelativePosition.z -= Double(chunkPosition.chunkZ*16)
    let cameraPosition = simd_float3([Float(-playerRelativePosition.x), Float(-(playerRelativePosition.y+1.625)), Float(-playerRelativePosition.z)])
    
    let worldToCamera = MatrixUtil.translationMatrix(cameraPosition) * MatrixUtil.rotationMatrix(y: 3.14)
    let cameraToClip = MatrixUtil.projectionMatrix(near: 1, far: 1000, aspect: aspect, fieldOfViewY: 3.14/2)
    var modelToClipSpace = worldToCamera * cameraToClip
    
    let matrixBuffer = metalDevice.makeBuffer(bytes: &modelToClipSpace, length: MemoryLayout<matrix_float4x4>.stride, options: [])!
    return matrixBuffer
  }
  
  func draw(view: MTKView, drawable: CAMetalDrawable) {
    Logger.debug("render, starting frame")
    var stopwatch = Stopwatch.now(label: "render")
    
    // render player's current chunk
    let mesh = Mesh()
    if let chunk = client.server.currentWorld.chunks[client.server.player.chunkPosition] {
//      let chunkRenderer = ChunkRenderer(chunk: chunk!)
//      chunkRenderer.render(into: mesh)
      
      if chunk.mesh.vertices.count == 0 {
        stopwatch.lap(detail: "generating chunk mesh")
        chunk.generateMesh()
        stopwatch.lap(detail: "finished generating chunk mesh")
        Logger.debug("number of blocks in mesh: \(chunk.mesh.totalBlocks)")
      }
      mesh.vertices = chunk.mesh.vertices
      mesh.indices = chunk.mesh.indices
    } else {
      mesh.vertices.append(contentsOf: [
        Vertex(position: [0, 1, -5], textureCoordinate: [0, 0]),
        Vertex(position: [0, 0, -5], textureCoordinate: [0, 1]),
        Vertex(position: [1, 0, -5], textureCoordinate: [1, 1])
      ])
      mesh.indices.append(contentsOf: [0, 1, 2])
    }
    
//    var chunkMesh = ChunkMesh()
//    chunkMesh.setBlock(5, 3, 10, to: 1)
//    chunkMesh.setBlock(6, 4, 10, to: 1)
//    chunkMesh.setBlock(8, 3, 10, to: 1)
//    chunkMesh.setBlock(0, 3, 10, to: 2)
//    chunkMesh.setBlock(0, 3, 10, to: 0)
//    mesh.vertices = chunkMesh.vertices
//    mesh.indices = chunkMesh.indices
    
    stopwatch.lap(detail: "created mesh objects")
    
    let aspect = Float(view.drawableSize.width/view.drawableSize.height)
    let matrixBuffer = createWorldToClipSpaceMatrix(aspect: aspect)
    let vertexBuffer = mesh.createVertexBuffer(for: metalDevice)
    let indexBuffer = mesh.createIndexBuffer(for: metalDevice)
    
    stopwatch.lap(detail: "created buffers")
    
    if let commandBuffer = metalCommandQueue.makeCommandBuffer() {
      if let renderPassDescriptor = view.currentRenderPassDescriptor {
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 1, 0, 1)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
          renderEncoder.setRenderPipelineState(pipelineState)
          renderEncoder.setDepthStencilState(depthState)
          
          renderEncoder.setFrontFacing(.clockwise)
          renderEncoder.setCullMode(.back)
          
          // // uncomment the lines below to enable wireframe
          // renderEncoder.setTriangleFillMode(.lines)
          // renderEncoder.setCullMode(.none)
          
          renderEncoder.setFragmentTexture(texture, index: 3)
          
          renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
          renderEncoder.setVertexBuffer(matrixBuffer, offset: 0, index: 1)
          renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: mesh.indices.count, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0)
          renderEncoder.endEncoding()
          
          commandBuffer.present(drawable)
          commandBuffer.commit()
          
          stopwatch.lap(detail: "rendered")
        }
      }
    }
  }
}
