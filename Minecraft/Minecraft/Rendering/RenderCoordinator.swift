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
  var frameTimes: [Double] = []
  var frameCounter = 0
  var client: Client
  
  init(client: Client) {
    Logger.debug("getting default metal device")
    renderer = Renderer(device: MTLCreateSystemDefaultDevice()!, client: client)
    self.client = client
  }
  
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    
  }
  
  func draw(in view: MTKView) {
    guard let drawable = view.currentDrawable else {
      Logger.warning("failed to get current drawable")
      return
    }
    
    var stopwatch = Stopwatch.now(label: "render coordinator")
    renderer.draw(view: view, drawable: drawable)
    stopwatch.lap(detail: "completed frame")
    let frameTime = (stopwatch.lastLap - stopwatch.start) * 1000
    frameTimes.append(frameTime)
    
    if frameCounter == 5 {
      let avgFrameTime = frameTimes.reduce(0.0, +)/Double(frameTimes.count)
      Logger.log(String(format: "average frame time: %.2fms", avgFrameTime))
      
      frameCounter = 0
      frameTimes = []
    }
    frameCounter += 1
  }
}
