import Foundation

/// Storage and manager for all currently loaded plugins.
public class PluginEnvironment: ObservableObject {
  /// Used to typecast the builder function in plugin dylibs.
  private typealias BuilderFunction = @convention(c) () -> UnsafeMutableRawPointer
  
  /// A map from plugin identifier to the current instance of that plugin and its manifest.
  @Published public var plugins: [String: (Plugin, PluginManifest)] = [:]
  /// Errors encountered while loading plugins.
  @Published public var errors: [(URL, Error)] = []
  
  /// Creates an empty plugin environment.
  public init() {}
  
  // MARK: Loading
  
  /// Loads all plugins contained within the specified directory.
  ///
  /// Plugins must be in the top level of the directory and must have the `.deltaplugin` file extension.
  ///
  /// - Parameter directory: Directory to load plugins from.
  public func loadPlugins(from directory: URL) throws {
    log.debug("Loading all plugins")
    let contents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [])
    for file in contents where file.pathExtension == "deltaplugin" {
      do {
        try loadPlugin(file)
      } catch {
        ThreadUtil.runInMain {
          errors.append((file, error))
        }
      }
    }
  }
  
  /// Loads a plugin from its bundle.
  /// - Parameter pluginBundle: The plugin's bundle directory.
  public func loadPlugin(_ pluginBundle: URL) throws {
    // Load the plugin's manifest file
    let manifest: PluginManifest
    do {
      let contents = try Data(contentsOf: pluginBundle.appendingPathComponent("manifest.json"))
      manifest = try JSONDecoder().decode(PluginManifest.self, from: contents)
    } catch {
      throw PluginLoadingError.invalidManifest(error)
    }
    
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
      plugins[manifest.identifier] = (plugin, manifest)
    }
    plugin.finishLoading()
  }
  
  // MARK: Unloading
  
  /// Unloads all loaded plugins.
  public func unloadAll() {
    log.debug("Unloading all plugins")
    for identifier in plugins.keys {
      unloadPlugin(identifier)
    }
  }
  
  /// Unloads the specified plugin if it's loaded. Does nothing if the plugin does not exist.
  /// - Parameter identifier: The identifier of the plugin to unload.
  public func unloadPlugin(_ identifier: String) {
    log.debug("Unloading plugin '\(identifier)'")
    if let plugin = plugins[identifier] {
      plugin.0.willUnload()
      ThreadUtil.runInMain {
        plugins.removeValue(forKey: identifier)
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
      plugin.0.willJoinServer(server: server, client: client)
    }
  }
  
  /// Sets up the environment to relay all events from an event bus to all loaded plugins.
  /// - Parameter eventBus: The event bus to listen to.
  public func addEventBus(_ eventBus: EventBus) {
    eventBus.registerHandler(handle(event:))
  }
  
  /// Notifies all loaded plugins of an event.
  /// - Parameter event: The event to notify all loaded plugins of.
  public func handle(event: Event) {
    for (_, (plugin, _)) in plugins {
      plugin.handle(event: event)
    }
  }
}
