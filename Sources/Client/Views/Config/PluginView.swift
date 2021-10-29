import SwiftUI
import DeltaCore

struct PluginView: View {
  @EnvironmentObject var pluginEnvironment: PluginEnvironment
  
	var body: some View {
		VStack {
			Text("Plugins").font(.title)
      
			HStack {
        // Loaded plugins
				VStack {
					Text("Loaded").font(.title2)
          
					ScrollView {
            ForEach(Array(pluginEnvironment.plugins), id: \.key) { (identifier, plugin) in
							HStack {
                Text(plugin.1.name)
                
								Button("Unload") {
                  pluginEnvironment.unloadPlugin(identifier)
								}
							}
						}
					}
				}.frame(maxWidth: .infinity)
        
        // Errors
				VStack {
					Text("Errors").font(.title2)
          
					ScrollView {
            ForEach(pluginEnvironment.errors, id: \.0) { (url, error) in
              Text("Error loading '\(url.lastPathComponent)': \(error.localizedDescription)")
						}
					}
				}.frame(maxWidth: .infinity)
			}
      
      // Global actions
			HStack {
				Button("Unload all") {
          pluginEnvironment.unloadAll()
				}
				Button("Reload All") {
          pluginEnvironment.unloadAll()
          do {
            try pluginEnvironment.loadPlugins(from: StorageManager.default.pluginsDirectory)
          } catch {
            DeltaClientApp.modalError("Failed to reload plugins after unloading all: \(error)", safeState: .serverList)
          }
				}
			}
		}
	}
}
