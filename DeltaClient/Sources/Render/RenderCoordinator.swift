//
//  RenderCoordinator.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import MetalKit
import os

class RenderCoordinator: NSObject, MTKViewDelegate {
  var client: Client
  
  var worldRenderer: WorldRenderer
  
  var commandQueue: MTLCommandQueue
  
  var stopwatch: Stopwatch
  var frameCounter = 0
  
  var logInterval = 60
  
  init(client: Client) {
    guard let device = MTLCreateSystemDefaultDevice() else {
      fatalError("failed to get metal device")
    }
    
    guard let commandQueue = device.makeCommandQueue() else {
      fatalError("failed to make render command queue")
    }
    
    self.client = client
    self.worldRenderer = WorldRenderer(client: client)
    self.stopwatch = Stopwatch(mode: .summary, name: "frame times")
    
    self.commandQueue = commandQueue
  }
  
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    
  }
  
  func willStartFrame() {
    stopwatch.startMeasurement("render frame")
  }
  
  func didFinishFrame() {
    stopwatch.stopMeasurement("render frame")
    
    if frameCounter == logInterval {
      stopwatch.summary()
      stopwatch.reset()
      frameCounter = 0
    }
    frameCounter += 1
  }
  
  func getClearColor() -> MTLClearColor {
    return MTLClearColorMake(0.65, 0.8, 1, 1)
  }
  
  func getAspectRatio(of view: MTKView) -> Float {
    return Float(view.drawableSize.width / view.drawableSize.height)
  }
  
  func draw(in view: MTKView) {
    guard let drawable = view.currentDrawable else {
      fatalError("failed to get current drawable")
    }
    
    guard let device = view.device else {
      fatalError("failed to get metal device (it used to be there)")
    }
    
    willStartFrame()
    
    let aspect = getAspectRatio(of: view)
    
    if let commandBuffer = commandQueue.makeCommandBuffer() {
      if let renderPassDescriptor = view.currentRenderPassDescriptor {
        renderPassDescriptor.colorAttachments[0].clearColor = getClearColor()
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
          // run renderers
          worldRenderer.draw(device: device, renderEncoder: renderEncoder, aspect: aspect)
          
          renderEncoder.endEncoding()
          commandBuffer.present(drawable)
          commandBuffer.commit()
        }
      }
    }
    
    didFinishFrame()
  }
}
