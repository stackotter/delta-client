import SwiftUI

#if !os(tvOS)
struct ControlsSettingsView: View {
  @EnvironmentObject var managedConfig: ManagedConfig

  @State var sensitivity: Float = 0
  @State var toggleSprint = false
  @State var toggleSneak = false

  var body: some View {
    ScrollView {
      HStack {
        Text("Sensitivity: \(Self.formatSensitivity(sensitivity))")
          .frame(width: 150)

        Slider(value: $sensitivity, in: 0...10, onEditingChanged: { isEditing in
          if !isEditing {
            sensitivity = Self.roundSensitivity(sensitivity)
            managedConfig.mouseSensitivity = sensitivity
          }
        })
      }
      .frame(width: 450)

      HStack {
        Text("Toggle sprint").frame(width: 150)
        Spacer()
        Toggle(
          "Toggle sprint",
          isOn: $toggleSprint.onChange { newValue in
            managedConfig.toggleSprint = newValue
          }
        )
          .labelsHidden()
          .toggleStyle(.switch)
        Spacer()
      }
      .frame(width: 400)

      HStack {
        Text("Toggle sneak").frame(width: 150)
        Spacer()
        Toggle(
          "Toggle sneak",
          isOn: $toggleSneak.onChange { newValue in
            managedConfig.toggleSneak = newValue
          }
        )
          .labelsHidden()
          .toggleStyle(.switch)
        Spacer()
      }
      .frame(width: 400)

      Text("Bindings")
        .font(.title)
        .padding(.top, 16)

      KeymapEditorView()
    }
    .onAppear {
      sensitivity = managedConfig.mouseSensitivity
      toggleSprint = managedConfig.toggleSprint
      toggleSneak = managedConfig.toggleSneak
    }
  }

  /// Rounds mouse sensitivity to the nearest even number percentage.
  private static func roundSensitivity(_ sensitivity: Float) -> Float {
    if abs(100 - sensitivity * 100) <= 3 {
      return 1
    }
    return Float(Int(round(sensitivity * 100 / 2)) * 2) / 100
  }

  /// Formats mouse sensitivity as a rounded percentage.
  private static func formatSensitivity(_ sensitivity: Float) -> String {
    return "\(Int(roundSensitivity(sensitivity) * 100))%"
  }
}
#endif
