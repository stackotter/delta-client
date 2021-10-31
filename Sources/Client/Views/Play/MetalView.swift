import Foundation
import DeltaCore
import MetalKit
import SwiftUI

final class MetalView: NSViewRepresentable {
  var renderCoordinator: RenderCoordinatorProtocol
  
  init(renderCoordinator: RenderCoordinatorProtocol) {
    self.renderCoordinator = renderCoordinator
  }
  
  func makeCoordinator() -> RenderCoordinatorProtocol {
    return renderCoordinator
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
