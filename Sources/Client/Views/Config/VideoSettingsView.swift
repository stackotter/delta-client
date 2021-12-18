import SwiftUI
import DeltaCore

struct VideoSettingsView: View {
  /// Config updates are sent straight to the client as soon as they are made if a client is provided.
  var client: Client?
  
  @State var renderDistance: Float = 0
  @State var fov: Float = 0
  @State var renderMode: RenderMode = .normal
  
  var config: RenderConfiguration {
    return RenderConfiguration(
      fovY: Float(fov.rounded()),
      renderDistance: Int(renderDistance),
      mode: renderMode)
  }
  
  /// - Parameter client: If present, config updates are sent to this client.
  init(client: Client? = nil) {
    self.client = client
  }
  
  /// Handles when the user changes a value.
  func onValueChanged<T>(_ newValue: T) {
    if let client = client {
      client.configuration.render = config
    }
  }
  
  /// Handles when the user stops/starts editing.
  func onEditingChanged(_ newValue: Bool) {
    // If the user has stopped editing, update config
    if newValue == false {
      save()
    }
  }
  
  /// Saves the user's choices to the config file.
  func save() {
    var config = ConfigManager.default.config
    config.render = self.config
    ConfigManager.default.setConfig(to: config)
  }
  
  var body: some View {
    ScrollView {
      HStack {
        Text("Render distance: \(Int(renderDistance))")
        Spacer()
        Slider(
          value: $renderDistance.onChange(onValueChanged),
          in: 0...32,
          step: 1,
          onEditingChanged: onEditingChanged
        )
          .frame(width: 220)
      }
      
      HStack {
        Text("FOV: \(Int(fov.rounded()))")
        Spacer()
        Slider(
          value: $fov.onChange(onValueChanged),
          in: 30...110,
          onEditingChanged: onEditingChanged
        )
          .frame(width: 220)
      }
      
      HStack {
        Text("Render mode")
        Spacer()
        Picker("Render mode", selection: $renderMode.onChange({ newValue in
          onValueChanged(newValue)
          save()
        })) {
          ForEach(RenderMode.allCases) { mode in
            Text(mode.rawValue.capitalized)
          }
        }
          .pickerStyle(RadioGroupPickerStyle())
          .frame(width: 220)
      }
    }
    .frame(width: 400)
    .navigationTitle("Video")
    .onAppear {
      let config = ConfigManager.default.config.render
      renderDistance = Float(config.renderDistance)
      fov = config.fovY
      renderMode = config.mode
    }
  }
}
