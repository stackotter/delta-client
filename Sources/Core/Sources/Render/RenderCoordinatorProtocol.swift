import Foundation
import MetalKit

/// The protocol render coordinators conform to. Render coordinators handle all the rendering stuff. They're called coordinators
/// because usually they just coordinate multiple smaller renderers for the different elements of the game.
public protocol RenderCoordinatorProtocol: NSObject, MTKViewDelegate {
  init(_ client: Client)
}
