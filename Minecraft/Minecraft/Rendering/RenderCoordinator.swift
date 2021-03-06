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
  var renderer: Renderer
  
  override init() {
    Logger.debug("getting default metal device")
    renderer = Renderer(device: MTLCreateSystemDefaultDevice()!)
    super.init()
  }
  
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    
  }
  
  func draw(in view: MTKView) {
    guard let drawable = view.currentDrawable else {
      Logger.warning("failed to get current drawable")
      return
    }
    
    renderer.draw(view: view, drawable: drawable)
  }
}
