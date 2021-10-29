import Foundation

/// Basic information about a plugin.
public struct PluginManifest: Codable {
  /// A unique identifier for the plugin. Should not be the same as any other plugins. A common format is `com.example.plugin`.
  public var identifier: String
  /// The display name for the plugin to display to users.
  public var name: String
  /// A brief description of the plugin.
  public var description: String
  /// The plugin's version (not the Delta Client version).
  public var version: String
  /// The name of your plugin's SwiftPM target.
  public var target: String
  
  public init(identifier: String, name: String, description: String, version: String, target: String) {
    self.identifier = identifier
    self.name = name
    self.description = description
    self.version = version
    self.target = target
  }
}
