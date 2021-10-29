/// A plugin that modifies the behaviour of the client.
public protocol Plugin {
  /// Creates a new instance of the plugin.
  init()
  
  /// Called when the plugin has been loaded into the plugin environment.
  func finishLoading()
  
  /// Called just before the plugin gets unloaded.
  ///
  /// Not called when the client gets closed, only when the plugin is unloaded through the UI.
  func willUnload()
  
  /// Called when the client is about to join a server.
  /// - Parameters:
  ///   - server: The server that the client will connect to.
  ///   - client: The client that is going to connect to the server.
  func willJoinServer(server: ServerDescriptor, client: Client)
  
  /// Called whenever an event is emitted by the client or another plugin.
  /// - Parameter event: The event that was emitted.
  func handle(event: Event)
}
