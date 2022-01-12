/// A plugin that modifies the behaviour of the client.
public protocol Plugin {
  // MARK: Init
  
  /// Creates a new instance of the plugin.
  init()
  
  // MARK: Lifecycle
  
  /// Called when the plugin has been loaded into the plugin environment.
  func finishLoading()
  
  /// Called just before the plugin gets unloaded.
  ///
  /// Not called when the client gets closed, only when the plugin is unloaded through the UI.
  func willUnload()
  
  // MARK: Event handling
  
  /// Called when the client is about to join a server.
  /// - Parameters:
  ///   - server: The server that the client will connect to.
  ///   - client: The client that is going to connect to the server.
  func willJoinServer(_ server: ServerDescriptor, client: Client)
  
  /// Called whenever an event is emitted by the client or another plugin.
  /// - Parameter event: The event that was emitted.
  func handle(_ event: Event)
}

public extension Plugin {
  func finishLoading() {}
  func willUnload() {}
  func willJoinServer(_ server: ServerDescriptor, client: Client) {}
  func handle(_ event: Event) {}
}
