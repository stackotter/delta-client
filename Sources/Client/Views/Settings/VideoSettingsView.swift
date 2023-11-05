import SwiftUI
import DeltaCore

struct VideoSettingsView: View {
  @EnvironmentObject var managedConfig: ManagedConfig

  var body: some View {
    ScrollView {
      HStack {
        Text("Render distance: \(managedConfig.render.renderDistance)")
        Spacer()
        Slider(
          value: Binding {
            Float(managedConfig.render.renderDistance)
          } set: { newValue in
            managedConfig.render.renderDistance = Int(newValue.rounded())
          },
          in: 0...32,
          step: 1
        )
          .frame(width: 220)
      }

      HStack {
        Text("FOV: \(Int(managedConfig.render.fovY.rounded()))")
        Spacer()
        Slider(
          value: Binding {
            managedConfig.render.fovY
          } set: { newValue in
            managedConfig.render.fovY = newValue.rounded()
          },
          in: 30...110
        )
          .frame(width: 220)
      }

      HStack {
        Text("Render mode")
        Spacer()
        Picker("Render mode", selection: $managedConfig.render.mode) {
          ForEach(RenderMode.allCases) { mode in
            Text(mode.rawValue.capitalized)
          }
        }
        #if os(macOS)
          .pickerStyle(RadioGroupPickerStyle())
        #elseif os(iOS)
          .pickerStyle(DefaultPickerStyle())
        #endif
          .frame(width: 220)
      }

      HStack {
        Text("Order independent transparency")
        Spacer()
        Toggle(
          "Order independent transparency",
          isOn: $managedConfig.render.enableOrderIndependentTransparency
        )
          .labelsHidden()
          .toggleStyle(.switch)
          .frame(width: 220)
      }
    }
    .frame(width: 450)
    .navigationTitle("Video")
  }
}
