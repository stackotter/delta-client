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

struct MetalView: NSViewRepresentable {
  var client: Client
  
  init(client: Client) {
    self.client = client
  }
  
  func makeCoordinator() -> RenderCoordinator {
    return RenderCoordinator(client: client)
  }
  
  func makeNSView(context: Context) -> some NSView {
    let mtkView = InteractiveMTKView()
    if let metalDevice = MTLCreateSystemDefaultDevice() {
      mtkView.device = metalDevice
    }
    mtkView.delegate = context.coordinator
    mtkView.preferredFramesPerSecond = 60
    mtkView.framebufferOnly = false
    mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
    mtkView.drawableSize = mtkView.frame.size
    mtkView.depthStencilPixelFormat = .depth32Float
    mtkView.clearDepth = 1.0
    
    // accept input
    mtkView.becomeFirstResponder()
    return mtkView
  }
  
  func updateNSView(_ view: NSViewType, context: Context) {
    
  }
}
