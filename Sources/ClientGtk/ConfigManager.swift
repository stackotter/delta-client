import DeltaCore

/// Dummy implementation of ClientConfiguration as required by DeltaCore.
class CoreConfiguration: ClientConfiguration {
	public var render = RenderConfiguration()
	public var keymap = Keymap.default
	public var toggleSprint = false
	public var toggleSneak = false
}
