import Foundation

public class PluginInitializer {
  private let pluginType: Plugin.Type
  
  func build() -> Plugin {
    return pluginType.init()
  }
  public static func buildSelf(pluginType: Plugin.Type) -> UnsafeMutableRawPointer {
    let builder = PluginInitializer(pluginType: pluginType)
    return Unmanaged.passRetained(builder).toOpaque()
  }
  private init(pluginType: Plugin.Type) {
    self.pluginType = pluginType
  }
}
