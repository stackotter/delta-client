import Foundation

open class PluginEnvironment: ObservableObject {
  @Published public var plugins: Dictionary<String, Plugin>
  
  public init() {
    plugins = [:]
  }
  
  public func handle(event: Event) {
    for (_, plugin) in plugins {
      plugin.handle(event: event)
    }
  }
  
  public func getHUDItems() -> Array<(hudItem: CustomHUDViewBuilder, plugin: Plugin)> {
    return plugins.reduce(into: []) { current, keyValuePair in
      current += keyValuePair.value.customHUDItems.map { return (hudItem: $0, plugin: keyValuePair.value) }
    }
  }
  
  public func addPlugin(at url: URL) throws {
    let pluginMetadata: PluginMetadata
    do {
      let manifestContents = try Data(contentsOf: url.appendingPathComponent("plugin.json"))
      pluginMetadata = try JSONDecoder().decode(PluginMetadata.self, from: manifestContents)
    } catch {
      throw PluginError.invalidManifest
    }
    
    guard pluginMetadata.apiVersion == PluginMetadata.currentAPIVersion else {
      throw PluginError.wrongAPIVersion
    }
    
    let relativeMetadata = PluginMetadata(
      name: pluginMetadata.name,
      version: pluginMetadata.version,
      apiVersion: pluginMetadata.apiVersion,
      dylibPath: url.appendingPathComponent(pluginMetadata.dylibPath).path,
      builderFunctionName: pluginMetadata.builderFunctionName
    )
    try addPlugin(pluginMetadata: relativeMetadata)
  }
  
  public func addPlugin(pluginMetadata: PluginMetadata) throws {
    let pluginLibrary = dlopen(pluginMetadata.dylibPath, RTLD_NOW|RTLD_LOCAL)
    defer {
      dlclose(pluginLibrary)
    }
    guard pluginLibrary != nil else {
      if let error = dlerror() {
        throw PluginError.libraryOpenError(reason: String(format: "%s", error))
      } else {
        throw PluginError.libraryOpenError(reason: nil)
      }
    }
    
    let pluginBuilderName = pluginMetadata.builderFunctionName
    let pluginBuilderSymbol = dlsym(pluginLibrary, pluginBuilderName)
    
    guard pluginBuilderSymbol != nil else {
      throw PluginError.builderNotFound
    }
    
    typealias BuilderFunction = @convention(c) () -> UnsafeMutableRawPointer
    let initBuilder: BuilderFunction = unsafeBitCast(pluginBuilderSymbol, to: BuilderFunction.self)
    let initPointer = initBuilder()
    let initObject = Unmanaged<PluginInitializer>.fromOpaque(initPointer).takeRetainedValue()
    let plugin = initObject.build()
    
    guard plugins[pluginMetadata.name] == nil else {
      throw PluginError.alreadyExists
    }
    plugins[pluginMetadata.name] = plugin
    plugin.handle(event: PluginLoadedEvent())
  }
}
