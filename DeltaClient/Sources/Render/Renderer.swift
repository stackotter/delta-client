//
//  Renderer.swift
//  DeltaClient
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
    depthState = device.makeDepthStencilState(descriptor: depthDescriptor)!
    
    Logger.debug("creating pipeline state")
    pipelineState = try! self.metalDevice.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    
    Logger.debug("loading textures")
    arrayTexture = managers.textureManager.createArrayTexture(metalDevice: metalDevice)
    
    Logger.debug("initialised renderer")
    
    self.logger = Logger(for: type(of: self))
  }
  
  func createUniformBuffer(aspect: Float) -> MTLBuffer {
    let playerPosition = client.server.player.position
    
    let look = client.server.player.look
    let xRot = look.pitch / 180 * Float.pi
    let yRot = look.yaw / 180 * Float.pi
    
    let fov = 90 / 180 * Float.pi
    
    let cameraPosition = simd_float3([Float(-playerPosition.x), Float(-(playerPosition.y+1.625)), Float(-playerPosition.z)])
    
    let worldToCamera = MatrixUtil.translationMatrix(cameraPosition) * MatrixUtil.rotationMatrix(y: -(Float.pi + yRot)) * MatrixUtil.rotationMatrix(x: -xRot)
    let cameraToClip = MatrixUtil.projectionMatrix(near: 0.1, far: 1000, aspect: aspect, fieldOfViewY: fov)
    let worldToClipSpace = worldToCamera * cameraToClip
    
    var uniforms = WorldUniforms(worldToClipSpace: worldToClipSpace)
    let uniformBuffer = metalDevice.makeBuffer(bytes: &uniforms, length: MemoryLayout<WorldUniforms>.stride, options: [])!
    uniformBuffer.label = "worldUniformBuffer"
    return uniformBuffer
  }
  
  func draw(view: MTKView, drawable: CAMetalDrawable) {
    // TODO: use chunk position to order chunk generation
    // generate chunk meshes if necessary
    var chunks: [Chunk] = []
    for (_, chunk) in client.server.currentWorld?.chunks ?? [:] {
      if chunk.mesh.isEmpty {
        chunk.generateMesh()
      }
      chunks.append(chunk)
    }
    
    // encode and send draw instructions
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
          
          // create uniforms
          let aspect = Float(view.drawableSize.width/view.drawableSize.height)
          let uniformBuffer = createUniformBuffer(aspect: aspect)
          renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
          
          for chunk in chunks {
            if !chunk.mesh.isEmpty {
              let buffers = chunk.mesh.createBuffers(device: metalDevice)
              
              renderEncoder.setVertexBuffer(buffers.vertexBuffer, offset: 0, index: 0) // set vertices
              renderEncoder.setVertexBuffer(buffers.uniformBuffer, offset: 0, index: 2) // set chunk specific uniforms
              renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: buffers.indexBuffer.length/4, indexType: .uint32, indexBuffer: buffers.indexBuffer, indexBufferOffset: 0)
            }
          }
          
          renderEncoder.endEncoding()
          
          commandBuffer.present(drawable)
          commandBuffer.commit()
        }
      }
    }
  }
}
