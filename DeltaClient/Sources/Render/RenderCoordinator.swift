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
  var renderer: Renderer
  var client: Client
  
  var stopwatch: Stopwatch
  var frameCounter = 0
  
  var logInterval = 60
  
  init(client: Client) {
    self.renderer = Renderer(device: MTLCreateSystemDefaultDevice()!, client: client)
    self.client = client
    self.stopwatch = Stopwatch(mode: .summary, name: "frame times")
  }
  
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    
  }
  
  func draw(in view: MTKView) {
    guard let drawable = view.currentDrawable else {
      Logger.error("failed to get current drawable")
      return
    }
    
    stopwatch.startMeasurement("render frame")
    renderer.draw(view: view, drawable: drawable)
    stopwatch.stopMeasurement("render frame")
    
    if frameCounter == logInterval {
      stopwatch.summary()
      stopwatch.reset()
      frameCounter = 0
    }
    frameCounter += 1
  }
}
