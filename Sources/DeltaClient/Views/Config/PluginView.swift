import SwiftUI
import DeltaCore

struct PluginView: View {
	@ObservedObject var pluginManager: PluginManager = PluginManager.shared
	@ObservedObject var pluginEnvironment: PluginEnvironment = PluginManager.shared.pluginEnvironment
	
	var body: some View {
		VStack {
			Text("Plugins")
				.font(.title)
			HStack {
				VStack {
					Text("Loaded")
						.font(.title2)
					ScrollView {
						ForEach(Array(pluginEnvironment.plugins), id: \.key) { plugin in
							HStack {
								Text(plugin.key)
								Button("Unload") {
									plugin.value.handle(event: BeforePluginUnloadedEvent())
									pluginEnvironment.plugins.removeValue(forKey: plugin.key)
								}
								Button("Force Unload") {
									pluginEnvironment.plugins.removeValue(forKey: plugin.key)
								}
									.foregroundColor(.red)
							}
						}
					}
				}
					.frame(maxWidth: .infinity)
				VStack {
					Text("Errors")
						.font(.title2)
					ScrollView {
						ForEach(pluginManager.pluginErrors, id: \.pluginDirectoryName) { error in
							Text("Error loading \(error.pluginDirectoryName): \(error.error.localizedDescription)")
						}
					}
				}
					.frame(maxWidth: .infinity)
			}
			HStack {
				Button("Reload Loaded") {
					PluginManager.shared.pluginEnvironment.handle(event: BeforePluginUnloadedEvent())
					for key in PluginManager.shared.pluginEnvironment.plugins.keys {
						let type = type(of: PluginManager.shared.pluginEnvironment.plugins[key]!)
						PluginManager.shared.pluginEnvironment.plugins[key] = type.init()
					}
				}
				Button("Reload All") {
					PluginManager.shared.pluginEnvironment.handle(event: BeforePluginUnloadedEvent())
					PluginManager.shared.pluginEnvironment.plugins = [:]
					PluginManager.shared.pluginErrors = []
					PluginManager.shared.addPlugins()
				}
				Button("Force Reload All") {
					PluginManager.shared.pluginEnvironment.plugins = [:]
					PluginManager.shared.pluginErrors = []
					PluginManager.shared.addPlugins()
				}
					.foregroundColor(.red)
			}
		}
	}
}
