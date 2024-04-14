import SwiftUI
import DeltaCore

struct VideoSettingsView: View {
  @EnvironmentObject var managedConfig: ManagedConfig

  var body: some View {
    ScrollView {
      HStack {
        Text("Render distance: \(managedConfig.render.renderDistance)")
        #if os(tvOS)
        ProgressView(value: Double(managedConfig.render.renderDistance) / 32)
        #else
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
        #endif
      }
      #if os(tvOS)
      .focusable()
      .onMoveCommand { direction in
        switch direction {
          case .left:
            managedConfig.render.renderDistance -= 1
          case .right:
            managedConfig.render.renderDistance += 1
          default:
            break
        }
      }
      #endif

      #if !os(tvOS)
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
      #endif

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
        #elseif os(iOS) || os(tvOS)
          .pickerStyle(DefaultPickerStyle())
        #endif
        #if !os(tvOS)
          .frame(width: 220)
        #endif
      }

      // Order independent transparency doesn't work on tvOS yet (our implementation uses a Metal
      // feature which isn't supported on tvOS).
      #if !os(tvOS)
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
      #endif
    }
    #if !os(tvOS)
    .frame(width: 450)
    #endif
    .navigationTitle("Video")
  }
}
