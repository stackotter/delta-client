import SwiftUI
import DeltaCore

#if os(macOS)
struct PluginSettingsView: View {
  @EnvironmentObject var pluginEnvironment: PluginEnvironment
  
  func updateConfig() {
    var config = ConfigManager.default.config
    config.unloadedPlugins = [String](pluginEnvironment.unloadedPlugins.keys)
    ConfigManager.default.setConfig(to: config)
  }
  
  var body: some View {
    VStack {
      HStack {
        // Loaded plugins
        VStack {
          Text("Loaded").font(.title2)
          
          ScrollView {
            ForEach(Array(pluginEnvironment.plugins), id: \.key) { (identifier, plugin) in
              HStack {
                Text(plugin.manifest.name)
                
                Button("Unload") {
                  pluginEnvironment.unloadPlugin(identifier)
                  updateConfig()
                }
              }
            }
            
            if pluginEnvironment.plugins.isEmpty {
              Text("no loaded plugins").italic()
            }
          }
        }.frame(maxWidth: .infinity)
        
        // Unloaded plugins
        VStack {
          Text("Unloaded").font(.title2)
          
          ScrollView {
            ForEach(Array(pluginEnvironment.unloadedPlugins), id: \.key) { (identifier, plugin) in
              HStack {
                Text(plugin.manifest.name)
                
                Button("Load") {
                  do {
                    try pluginEnvironment.loadPlugin(from: plugin.bundle)
                  } catch {
                    DeltaClientApp.modalError("Failed to load plugin '\(identifier)': \(error)")
                  }
                  updateConfig()
                }
              }
            }
            
            if pluginEnvironment.unloadedPlugins.isEmpty {
              Text("no unloaded plugins").italic()
            }
          }
        }.frame(maxWidth: .infinity)
        
        // Errors
        if !pluginEnvironment.errors.isEmpty {
          VStack {
            HStack {
              Text("Errors").font(.title2)
              Button("Clear") {
                pluginEnvironment.errors = []
              }
            }
            
            ScrollView {
              VStack(alignment: .leading) {
                ForEach(Array(pluginEnvironment.errors.enumerated()), id: \.0) { (_, error) in
                  Text("\(error.bundle):").font(.title)
                  Text(String("\(error.underlyingError)"))
                }
              }
            }
          }.frame(maxWidth: .infinity)
        }
      }
      
      // Global actions
      HStack {
        Button("Unload all") {
          pluginEnvironment.unloadAll()
          updateConfig()
        }
        Button("Reload all") {
          pluginEnvironment.reloadAll(StorageManager.default.pluginsDirectory)
          updateConfig()
        }
        Button("Open plugins directory") {
          NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: StorageManager.default.pluginsDirectory.path)
        }
      }
    }
  }
}
#endif
