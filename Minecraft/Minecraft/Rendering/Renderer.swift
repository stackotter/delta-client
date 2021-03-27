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
  
  var arrayTexture: MTLTexture
  
  var client: Client
  var managers: Managers
  
  let skyColor = MTLClearColorMake(0.65, 0.8, 1, 1)
  
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
    arrayTexture = managers.textureManager.createArrayTexture(metalDevice: metalDevice)
    
    Logger.debug("initialised renderer")
    
    self.logger = Logger(for: type(of: self))
  }
  
  func createWorldToClipSpaceMatrix(aspect: Float) -> MTLBuffer {
    let chunkPosition = client.server.player.chunkPosition
    var playerRelativePosition = client.server.player.position
    playerRelativePosition.x -= Double(chunkPosition.chunkX*16)
    playerRelativePosition.z -= Double(chunkPosition.chunkZ*16)
    
    let look = client.server.player.look
    let xRot = look.pitch / 180 * Float.pi
    let yRot = look.yaw / 180 * Float.pi
    
    let fov = 90 / 180 * Float.pi
    
    let cameraPosition = simd_float3([Float(-playerRelativePosition.x), Float(-(playerRelativePosition.y+1.625)), Float(-playerRelativePosition.z)])
    
    let worldToCamera = MatrixUtil.translationMatrix(cameraPosition) * MatrixUtil.rotationMatrix(y: -(Float.pi + yRot)) * MatrixUtil.rotationMatrix(x: -xRot)
    let cameraToClip = MatrixUtil.projectionMatrix(near: 0.0001, far: 1000, aspect: aspect, fieldOfViewY: fov)
    var modelToClipSpace = worldToCamera * cameraToClip
    
    let matrixBuffer = metalDevice.makeBuffer(bytes: &modelToClipSpace, length: MemoryLayout<matrix_float4x4>.stride, options: [])!
    return matrixBuffer
  }
  
  func draw(view: MTKView, drawable: CAMetalDrawable) {
    var stopwatch = Stopwatch(mode: .verbose, name: "chunk mesh")
    
    // render player's current chunk
    if let chunk = client.server.currentWorld.chunks[client.server.player.chunkPosition] {
      if chunk.mesh.isEmpty {
        stopwatch.startMeasurement(category: "generate chunk mesh")
        chunk.generateMesh(with: managers.blockModelManager)
        stopwatch.stopMeasurement(category: "generate chunk mesh")
      }
      if !chunk.mesh.isEmpty {
        let aspect = Float(view.drawableSize.width/view.drawableSize.height)
        let matrixBuffer = createWorldToClipSpaceMatrix(aspect: aspect)
        let vertexBuffer = chunk.mesh.createVertexBuffer(for: metalDevice)
        let indexBuffer = chunk.mesh.createIndexBuffer(for: metalDevice)
        
        if let commandBuffer = metalCommandQueue.makeCommandBuffer() {
          if let renderPassDescriptor = view.currentRenderPassDescriptor {
            renderPassDescriptor.colorAttachments[0].clearColor = skyColor
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].storeAction = .store
            
            if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
              renderEncoder.setRenderPipelineState(pipelineState)
              renderEncoder.setDepthStencilState(depthState)
              
              renderEncoder.setFrontFacing(.clockwise)
              renderEncoder.setCullMode(.back)
              
              // uncomment the lines below to enable wireframe
              // renderEncoder.setTriangleFillMode(.lines)
              // renderEncoder.setCullMode(.none)
              
              renderEncoder.setFragmentTexture(arrayTexture, index: 0)
              
              renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
              renderEncoder.setVertexBuffer(matrixBuffer, offset: 0, index: 1)
              renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: chunk.mesh.numIndices, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0)
              renderEncoder.endEncoding()
              
              commandBuffer.present(drawable)
              commandBuffer.commit()
            }
          }
        }
      }
    }
  }
}
