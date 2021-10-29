import Foundation

public protocol Plugin: AnyObject {
  init()
  func handle(event: Event)
  var alternateRenderCoordinator: RenderCoordinator? { get }
  var customHUDItems: Array<CustomHUDViewBuilder> { get }
}
