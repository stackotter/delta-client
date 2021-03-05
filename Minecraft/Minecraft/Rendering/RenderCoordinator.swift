//
//  RenderCoordinator.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import MetalKit
import os

class RenderCoordinator: NSObject, MTKViewDelegate {
  var metalDevice: MTLDevice!
  var metalCommandQueue: MTLCommandQueue
  var logger: Logger
  
  override init() {
    if let metalDevice = MTLCreateSystemDefaultDevice() {
      self.metalDevice = metalDevice
    }
    self.metalCommandQueue = metalDevice.makeCommandQueue()!
    logger = Logger(for: type(of: self))
    super.init()
  }
  
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    
  }
  
  func draw(in view: MTKView) {
    guard let drawable = view.currentDrawable else {
      logger.warning("failed to get current drawable")
      return
    }
    
    if let commandBuffer = metalCommandQueue.makeCommandBuffer() {
      if let renderPassDescriptor = view.currentRenderPassDescriptor {
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 1, 0, 1)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        if let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
          commandEncoder.endEncoding()
          commandBuffer.present(drawable)
          commandBuffer.commit()
        }
      }
    }
  }
}
