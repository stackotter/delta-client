//
//  MetalView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import DeltaCore
import MetalKit
import SwiftUI

final class MetalView: NSViewRepresentable {
  var client: Client
  
  init(client: Client) {
    self.client = client
  }
  
  func makeCoordinator() -> RenderCoordinator {
    return RenderCoordinator(client: client)
  }
  
  func makeNSView(context: Context) -> some NSView {
    let mtkView = MTKView()
    
    if let metalDevice = MTLCreateSystemDefaultDevice() {
      mtkView.device = metalDevice
    }
    mtkView.delegate = context.coordinator
    mtkView.preferredFramesPerSecond = 60
    mtkView.framebufferOnly = true
    mtkView.clearColor = MTLClearColorMake(0.65, 0.8, 1, 1) // Sky colour
    mtkView.drawableSize = mtkView.frame.size
    mtkView.depthStencilPixelFormat = .depth32Float
    mtkView.clearDepth = 1.0
    
    // Accept input
    mtkView.becomeFirstResponder()
    return mtkView
  }
  
  func updateNSView(_ view: NSViewType, context: Context) {
    
  }
}
