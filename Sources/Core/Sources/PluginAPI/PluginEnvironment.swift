import Foundation
import OrderedCollections

/// Storage and manager for all currently loaded plugins.
public class PluginEnvironment: ObservableObject {
  /// Used to typecast the builder function in plugin dylibs.
  private typealias BuilderFunction = @convention(c) () -> UnsafeMutableRawPointer
  
  /// A map from plugin identifier to the current instance of that plugin, its bundle url and its manifest.
  @Published public var plugins: OrderedDictionary<String, (Plugin, URL, PluginManifest)> = [:]
  /// Plugins that are unloaded
  @Published public var unloadedPlugins: OrderedDictionary<String, (URL, PluginManifest)> = [:]
  /// Errors encountered while loading plugins. `bundle` is the filename of the plugin's bundle.
  @Published public var errors: [(bundle: String, error: Error)] = []
  
  /// Creates an empty plugin environment.
  public init() {}
  
  // MARK: Access
  
  /// Returns the specified plugin if it's loaded.
  public func plugin(_ identifier: String) -> Plugin? {
    return plugins[identifier]?.0
  }
  
  // MARK: Loading
  
  /// Loads all plugins contained within the specified directory.
  ///
  /// Plugins must be in the top level of the directory and must have the `.deltaplugin` file extension.
  ///
  /// Throws if it fails to enumerate the contents of `directory`. Any errors from plugin loading are added to ``errors``.
  ///
  /// - Parameter directory: Directory to load plugins from.
  /// - Parameter excludedIdentifiers: Identifier's of plugins to keep as unloaded (they will still be registered though).
  public func loadPlugins(from directory: URL, excluding excludedIdentifiers: [String] = []) throws {
    let contents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [])
    for file in contents where file.pathExtension == "deltaplugin" {
      do {
        let manifest = try loadPluginManifest(file)
        if excludedIdentifiers.contains(manifest.identifier) || unloadedPlugins.keys.contains(manifest.identifier) {
          log.info("Skipping plugin '\(manifest.identifier)' (\(file.lastPathComponent))")
          ThreadUtil.runInMain {
            unloadedPlugins[manifest.identifier] = (file, manifest)
          }
          continue
        }
        try loadPlugin(file, manifest)
      } catch {
        ThreadUtil.runInMain {
          errors.append((bundle: file.lastPathComponent, error: error))
        }
      }
    }
  }
  
  /// Loads a plugin from its bundle.
  /// - Parameter pluginBundle: The plugin's bundle directory.
  /// - Parameter manifest: The plugin's manifest. If not provided, the manifest is loaded from the bundle.
  public func loadPlugin(_ pluginBundle: URL, _ manifest: PluginManifest? = nil) throws {
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
    
    // Make sure the dylib gets closed when this function exits
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
      plugins[manifest.identifier] = (plugin, pluginBundle, manifest)
      unloadedPlugins.removeValue(forKey: manifest.identifier)
    }
    plugin.finishLoading()
  }
  
  /// Loads a plugin's manifest from its bundle.
  /// - Parameter pluginBundle: The plugin's bundle directory.
  public func loadPluginManifest(_ pluginBundle: URL) throws -> PluginManifest {
    do {
      let contents = try Data(contentsOf: pluginBundle.appendingPathComponent("manifest.json"))
      return try JSONDecoder().decode(PluginManifest.self, from: contents)
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
    
    for (_, (_, bundle, _)) in plugins {
      do {
        try loadPlugin(bundle)
      } catch {
        errors.append((bundle: bundle.lastPathComponent, error: error))
      }
    }
    
    if let directory = directory {
      try? loadPlugins(from: directory)
    }
  }
  
  // MARK: Unloading
  
  /// Unloads all loaded plugins.
  public func unloadAll(keepRegistered: Bool = true) {
    log.debug("Unloading all plugins")
    for identifier in plugins.keys {
      unloadPlugin(identifier, keepRegistered: keepRegistered)
    }
  }
  
  /// Unloads the specified plugin if it's loaded. Does nothing if the plugin does not exist.
  /// - Parameter identifier: The identifier of the plugin to unload.
  /// - Parameter keepRegistered: If `true`, the client will remember the plugin and keep it in ``unloadedPlugins``.
  public func unloadPlugin(_ identifier: String, keepRegistered: Bool = true) {
    log.debug("Unloading plugin '\(identifier)'")
    if let plugin = plugins[identifier] {
      plugin.0.willUnload()
      ThreadUtil.runInMain {
        plugins.removeValue(forKey: identifier)
        if keepRegistered {
          unloadedPlugins[identifier] = (plugin.1, plugin.2)
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
      plugin.0.willJoinServer(server, client: client)
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
    for (_, (plugin, _, _)) in plugins {
      plugin.handle(event)
    }
  }
}
