import Foundation

/// Used to transport a plugin from its dylib to the client.
public class PluginBuilder {
  /// The type of plugin to build.
  public var pluginType: Plugin.Type
  
  /// A retained opaque pointer that points to this builder.
  public var retainedOpaquePointer: UnsafeMutableRawPointer {
    return Unmanaged.passRetained(self).toOpaque()
  }
  
  /// Creates a builder for the specified plugin.
  public init(_ pluginType: Plugin.Type) {
    self.pluginType = pluginType
  }
  
  /// Creates an instance of the plugin this builder was created for.
  public func build() -> Plugin {
    return pluginType.init()
  }
}
