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
  
  var angle: Float = 0
  
  init(device: MTLDevice) {
    self.metalDevice = device
    
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
    let textureURL = Bundle.main.urlForImageResource("chiseled_stone_bricks")!
    let textureLoader = MTKTextureLoader(device: self.metalDevice)
    texture = try! textureLoader.newTexture(URL: textureURL)
    
    Logger.debug("initialised renderer")
    
    self.logger = Logger(for: type(of: self))
  }
  
  func createWorldToClipSpaceMatrix(aspect: Float) -> MTLBuffer {
    let cameraPosition = simd_float3([0, 0, -3])
    
    var worldToCamera = MatrixUtil.rotationMatrix(x: Float(3.14/8.0))
//    worldToCamera = worldToCamera * MatrixUtil.rotationMatrix(y: 0)
    worldToCamera = worldToCamera * MatrixUtil.translationMatrix(cameraPosition)
    
    let cameraToClip = MatrixUtil.projectionMatrix(near: 1, far: 100, aspect: aspect, fieldOfViewY: 1.1)
    
    var modelToClipSpace = worldToCamera * cameraToClip
    let matrixBuffer = metalDevice.makeBuffer(bytes: &modelToClipSpace, length: MemoryLayout<matrix_float4x4>.stride, options: [])!
    return matrixBuffer
  }
  
  func draw(view: MTKView, drawable: CAMetalDrawable) {
    var stopWatch = Stopwatch.now(label: "render")
    
    let aspect = Float(view.drawableSize.width/view.drawableSize.height)
    
    var cubes: [CubeMesh] = []
    for x in -5...5 {
      cubes.append(CubeMesh(faces: .init(rawValue: 0xff), position: [Float(x), 0, -5]))
    }
    
    stopWatch.lap(detail: "created mesh objects")
    
    let mesh = Mesh()
    
    for cube in cubes {
      cube.prepare(into: mesh)
    }
    
    stopWatch.lap(detail: "prepared meshes")
    
    let vertexBuffer = mesh.createVertexBuffer(for: metalDevice)
    let indexBuffer = mesh.createIndexBuffer(for: metalDevice)
    let translationsBuffer = mesh.createTranslationsBuffer(for: metalDevice)
    let matrixBuffer = createWorldToClipSpaceMatrix(aspect: aspect)
    
    stopWatch.lap(detail: "created buffers")
    
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
          renderEncoder.setVertexBuffer(translationsBuffer, offset: 0, index: 2)
          renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: mesh.indices.count, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0)
          renderEncoder.endEncoding()
          
          commandBuffer.present(drawable)
          commandBuffer.commit()
          
          stopWatch.lap(detail: "rendered")
        }
      }
    }
  }
}
