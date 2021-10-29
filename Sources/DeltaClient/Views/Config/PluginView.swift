import SwiftUI
import DeltaCore

struct PluginView: View {
	var body: some View {
		VStack {
			Text("Plugins").font(.title)
      
			HStack {
        // Loaded plugins
				VStack {
					Text("Loaded").font(.title2)
          
					ScrollView {
            ForEach(Array(DeltaClientApp.pluginEnvironment.plugins), id: \.key) { (identifier, plugin) in
							HStack {
                Text(plugin.1.name)
                
								Button("Unload") {
                  DeltaClientApp.pluginEnvironment.unloadPlugin(identifier)
								}
							}
						}
					}
				}.frame(maxWidth: .infinity)
        
        // Errors
				VStack {
					Text("Errors").font(.title2)
          
					ScrollView {
            ForEach(DeltaClientApp.pluginEnvironment.errors, id: \.0) { (url, error) in
              Text("Error loading '\(url.lastPathComponent)': \(error.localizedDescription)")
						}
					}
				}.frame(maxWidth: .infinity)
			}
      
      // Global actions
			HStack {
				Button("Unload all") {
          DeltaClientApp.pluginEnvironment.unloadAll()
				}
				Button("Reload All") {
          DeltaClientApp.pluginEnvironment.unloadAll()
          do {
            try DeltaClientApp.pluginEnvironment.loadPlugins(from: StorageManager.default.pluginsDirectory)
          } catch {
            DeltaClientApp.modalError("Failed to reload plugins after unloading all: \(error)", safeState: .serverList)
          }
				}
			}
		}
	}
}
