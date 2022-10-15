import Foundation
import OrderedCollections
import ZippyJSON

/// Storage and manager for all currently loaded plugins.
public class PluginEnvironment: ObservableObject {
  /// Used to typecast the builder function in plugin dylibs.
  private typealias BuilderFunction = @convention(c) () -> UnsafeMutableRawPointer
  
  /// The plugins that are currently loaded (keyed by plugin identifier).
  @Published public var plugins: OrderedDictionary<String, LoadedPlugin> = [:]
  /// Plugins that are unloaded.
  @Published public var unloadedPlugins: OrderedDictionary<String, UnloadedPlugin> = [:]
  /// Errors encountered while loading plugins. `bundle` is the filename of the plugin's bundle.
  @Published public var errors: [PluginError] = []

  /// A plugin which has been loaded.
  public struct LoadedPlugin {
    /// The plugin which was loaded.
    public var plugin: Plugin
    /// The location of the plugin.
    public var bundle: URL
    /// Information about the plugin loaded from its manifest file.
    public var manifest: PluginManifest

    /// The unloaded version of this plugin.
    public var unloaded: UnloadedPlugin {
      UnloadedPlugin(bundle: bundle, manifest: manifest)
    }
  }

  /// A plugin which has been unloaded.
  public struct UnloadedPlugin {
    /// The location of the plugin.
    public var bundle: URL
    /// Information about the plugin loaded from its manifest file.
    public var manifest: PluginManifest
  }

  /// An error related to a particular plugin.
  public struct PluginError: LocalizedError {
    /// The bundle of the plugin that the error occurred for.
    public let bundle: String
    /// The underlying error that caused this error to be thrown if any.
    public let underlyingError: Error
    
    public var errorDescription: String? {
      """
      \(String(describing: Self.self)).
      Reason: \(underlyingError.localizedDescription)
      Bundle: \(bundle)
      """
    }
  }

  // MARK: Init
  
  /// Creates an empty plugin environment.
  public init() {}
  
  // MARK: Access
  
  /// Returns the specified plugin if it's loaded.
  public func plugin(_ identifier: String) -> Plugin? {
    return plugins[identifier]?.plugin
  }
  
  // MARK: Loading
  
  /// Loads all plugins contained within the specified directory.
  ///
  /// Plugins must be in the top level of the directory and must have the `.deltaplugin` file extension.
  ///
  /// Throws if it fails to enumerate the contents of `directory`. Any errors from plugin loading are added to ``errors``.
  /// - Parameter directory: Directory to load plugins from.
  /// - Parameter excludedIdentifiers: Identifier's of plugins to keep as unloaded (they will still be registered though).
  public func loadPlugins(from directory: URL, excluding excludedIdentifiers: [String] = []) throws {
    let contents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [])
    for file in contents where file.pathExtension == "deltaplugin" {
      if plugins.values.contains(where: { $0.bundle == file }) {
        continue
      }
      do {
        let manifest = try loadPluginManifest(file)
        if excludedIdentifiers.contains(manifest.identifier) || unloadedPlugins.keys.contains(manifest.identifier) {
          log.info("Skipping plugin '\(manifest.identifier)' (\(file.lastPathComponent))")
          ThreadUtil.runInMain {
            unloadedPlugins[manifest.identifier] = UnloadedPlugin(bundle: file, manifest: manifest)
          }
          continue
        }
        try loadPlugin(from: file, manifest)
      } catch {
        ThreadUtil.runInMain {
          errors.append(PluginError(bundle: file.lastPathComponent, underlyingError: error))
        }
      }
    }
  }
  
  /// Loads a plugin from its bundle.
  /// - Parameter pluginBundle: The plugin's bundle directory.
  /// - Parameter manifest: The plugin's manifest. If not provided, the manifest is loaded from the bundle.
  public func loadPlugin(from pluginBundle: URL, _ manifest: PluginManifest? = nil) throws {
    let manifest = try manifest ?? loadPluginManifest(pluginBundle)
    
    log.info("Loading plugin '\(manifest.identifier)' ('\(pluginBundle.lastPathComponent)')")
    
    // Check that the plugin isn't already loaded
    guard plugins[manifest.identifier] == nil else {
      throw PluginLoadingError.alreadyLoaded
    }
    
    // Open the plugin's dylib
    guard let pluginLibrary = dlopen(pluginBundle.appendingPathComponent("libPlugin.dylib").path, RTLD_NOW|RTLD_LOCAL) else {
      if let error = dlerror() {
        throw PluginLoadingError.failedToOpenDylib(String(format: "%s", error))
      } else {
        throw PluginLoadingError.failedToOpenDylib(nil)
      }
    }
    
    // Make sure the dylib gets closed when it's not required anymore
    defer {
      dlclose(pluginLibrary)
    }
    
    // Get the plugin's builder function
    guard let pluginBuilderSymbol = dlsym(pluginLibrary, "buildPlugin") else {
      throw PluginLoadingError.missingBuilderFunction
    }
    
    let buildBuilder: BuilderFunction = unsafeBitCast(pluginBuilderSymbol, to: BuilderFunction.self)
    let builder = Unmanaged<PluginBuilder>.fromOpaque(buildBuilder()).takeRetainedValue()
    let plugin = builder.build()
    
    ThreadUtil.runInMain {
      plugins[manifest.identifier] = LoadedPlugin(plugin: plugin, bundle: pluginBundle, manifest: manifest)
      unloadedPlugins.removeValue(forKey: manifest.identifier)
    }
    plugin.finishLoading()
  }
  
  /// Loads a plugin's manifest from its bundle.
  /// - Parameter pluginBundle: The plugin's bundle directory.
  public func loadPluginManifest(_ pluginBundle: URL) throws -> PluginManifest {
    do {
      let contents = try Data(contentsOf: pluginBundle.appendingPathComponent("manifest.json"))
      return try CustomJSONDecoder().decode(PluginManifest.self, from: contents)
    } catch {
      throw PluginLoadingError.invalidManifest(error)
    }
  }
  
  /// Reloads all currently loaded plugins.
  /// - Parameter directory: A directory to check for new plugins in (any plugins that are currently unloaded will be skipped).
  public func reloadAll(_ directory: URL? = nil) {
    ThreadUtil.runInMain {
      errors = []
    }
    
    let plugins = self.plugins
    unloadAll(keepRegistered: false)
    
    for (_, plugin) in plugins {
      do {
        try loadPlugin(from: plugin.bundle)
      } catch {
        errors.append(PluginError(bundle: plugin.bundle.lastPathComponent, underlyingError: error))
      }
    }
    
    if let directory = directory {
      try? loadPlugins(from: directory)
    }
  }
  
  // MARK: Unloading
  
  /// Unloads all loaded plugins.
  /// - Parameter keepRegistered: If `true`, the client will remember the plugins and keep them in ``unloadedPlugins``.
  ///                             This keeps the plugins unloaded across sessions.
  public func unloadAll(keepRegistered: Bool = true) {
    log.debug("Unloading all plugins")
    for identifier in plugins.keys {
      unloadPlugin(identifier, keepRegistered: keepRegistered)
    }
  }
  
  /// Unloads the specified plugin if it's loaded. Does nothing if the plugin does not exist.
  /// - Parameter identifier: The identifier of the plugin to unload.
  /// - Parameter keepRegistered: If `true`, the client will remember the plugin and keep it in ``unloadedPlugins``.
  ///                             This keeps the plugin unloaded across sessions.
  public func unloadPlugin(_ identifier: String, keepRegistered: Bool = true) {
    log.debug("Unloading plugin '\(identifier)'")
    if let plugin = plugins[identifier] {
      plugin.plugin.willUnload()
      ThreadUtil.runInMain {
        plugins.removeValue(forKey: identifier)
        if keepRegistered {
          unloadedPlugins[identifier] = plugin.unloaded
        }
      }
    }
  }
  
  // MARK: Event handling
  
  /// Called when the client is about to join a server.
  /// - Parameters:
  ///   - server: The server that the client will connect to.
  ///   - client: The client that is going to connect to the server.
  public func handleWillJoinServer(server: ServerDescriptor, client: Client) {
    for (_, plugin) in plugins {
      plugin.plugin.willJoinServer(server, client: client)
    }
  }
  
  /// Sets up the environment to relay all events from an event bus to all loaded plugins.
  /// - Parameter eventBus: The event bus to listen to.
  public func addEventBus(_ eventBus: EventBus) {
    eventBus.registerHandler { [weak self] event in
      guard let self = self else { return }
      self.handle(event: event)
    }
  }
  
  /// Notifies all loaded plugins of an event.
  /// - Parameter event: The event to notify all loaded plugins of.
  public func handle(event: Event) {
    for (_, plugin) in plugins {
      plugin.plugin.handle(event)
    }
  }
}
