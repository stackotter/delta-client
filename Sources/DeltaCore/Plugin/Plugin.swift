import Foundation

public protocol Plugin: AnyObject {
	init()
	func handle(event: Event)
	var alternateRenderCoordinator: RenderCoordinator.Type? { get }
	var customHUDItems: Array<CustomHUDViewBuilder> { get }
}
