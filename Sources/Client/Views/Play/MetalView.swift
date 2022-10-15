import Foundation
import DeltaCore
import MetalKit
import SwiftUI

@available(macOS 13, *)
@available(iOS 16, *)
struct MetalView {
  var renderCoordinator: RenderCoordinator
  
  init(renderCoordinator: RenderCoordinator) {
    self.renderCoordinator = renderCoordinator
  }

  func makeCoordinator() -> RenderCoordinator {
    return renderCoordinator
  }

  func makeMTKView(renderCoordinator: RenderCoordinator) -> MTKView {
    let mtkView = MTKView()
    
    if let metalDevice = MTLCreateSystemDefaultDevice() {
      mtkView.device = metalDevice
    }
    
    mtkView.delegate = renderCoordinator
    mtkView.preferredFramesPerSecond = 10000
    mtkView.framebufferOnly = true
    mtkView.clearColor = MTLClearColorMake(0.65, 0.8, 1, 1) // Sky colour
    mtkView.drawableSize = mtkView.frame.size
    mtkView.depthStencilPixelFormat = .depth32Float // No depth stencil for view
    
    // Accept input
    mtkView.becomeFirstResponder()
    return mtkView
  }
}

@available(macOS, deprecated: 13, renamed: "MetalView")
@available(iOS, deprecated: 16, renamed: "MetalView")
final class MetalViewClass {
  var renderCoordinator: RenderCoordinator
  
  init(renderCoordinator: RenderCoordinator) {
    self.renderCoordinator = renderCoordinator
  }

  func makeCoordinator() -> RenderCoordinator {
    return renderCoordinator
  }

  func makeMTKView(renderCoordinator: RenderCoordinator) -> MTKView {
    let mtkView = MTKView()
    
    if let metalDevice = MTLCreateSystemDefaultDevice() {
      mtkView.device = metalDevice
    }
    
    mtkView.delegate = renderCoordinator
    mtkView.preferredFramesPerSecond = 10000
    mtkView.framebufferOnly = true
    mtkView.clearColor = MTLClearColorMake(0.65, 0.8, 1, 1) // Sky colour
    mtkView.drawableSize = mtkView.frame.size
    mtkView.depthStencilPixelFormat = .depth32Float
    mtkView.clearDepth = 1.0
    
    // Accept input
    mtkView.becomeFirstResponder()
    return mtkView
  }
}


#if os(macOS)

@available(macOS 13, *)
@available(iOS 16, *)
extension MetalView: NSViewRepresentable {
  func makeNSView(context: Context) -> some NSView {
    return makeMTKView(renderCoordinator: context.coordinator)
  }
  
  func updateNSView(_ view: NSViewType, context: Context) {}
}

extension MetalViewClass: NSViewRepresentable {
  func makeNSView(context: Context) -> some NSView {
    return makeMTKView(renderCoordinator: context.coordinator)
  }
  
  func updateNSView(_ view: NSViewType, context: Context) {}
}
#elseif os(iOS)
extension MetalView: UIViewRepresentable {
  func makeUIView(context: Context) -> some UIView {
    return makeMTKView(renderCoordinator: context.coordinator)
  }
  
  func updateUIView(_ view: UIViewType, context: Context) {}
}
#else
#error("Unsupported platform, no MetalView SwiftUI compatibility")
#endif
