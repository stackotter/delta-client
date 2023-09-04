import SwiftUI

struct ControlsSettingsView: View {
  @State var sensitivity = ConfigManager.default.config.mouseSensitivity
  @State var toggleSprint = ConfigManager.default.config.toggleSprint
  @State var toggleSneak = ConfigManager.default.config.toggleSneak

  var body: some View {
    ScrollView {
      HStack {
        Text("Sensitivity: \(Self.formatSensitivity(sensitivity))")
          .frame(width: 150)

        Slider(value: $sensitivity, in: 0...10, onEditingChanged: { isEditing in
          if !isEditing {
            sensitivity = Self.roundSensitivity(sensitivity)
            var config = ConfigManager.default.config
            config.mouseSensitivity = sensitivity
            ConfigManager.default.setConfig(to: config)
          }
        })
      }
      .frame(width: 450)

      InputView(passthroughMouseClicks: false) { inputCaptured, delegateSetter in
        KeymapEditorView(
          inputCaptured: inputCaptured,
          inputDelegateSetter: delegateSetter
        )
      }

      HStack {
        Text("Toggle sprint").frame(width: 150)
        Spacer()
        Toggle(
          "Toggle sprint",
          isOn: $toggleSprint.onChange { newValue in
            var config = ConfigManager.default.config
            config.toggleSprint = newValue
            ConfigManager.default.setConfig(to: config)
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
            var config = ConfigManager.default.config
            config.toggleSneak = newValue
            ConfigManager.default.setConfig(to: config)
          }
        )
          .labelsHidden()
          .toggleStyle(.switch)
        Spacer()
      }
      .frame(width: 400)
    }
  }

  /// Rounds sensitivity to the nearest even number percentage.
  private static func roundSensitivity(_ sensitivity: Float) -> Float {
    if abs(100 - sensitivity * 100) <= 3 {
      return 1
    }
    return Float(Int(round(sensitivity * 100 / 2)) * 2) / 100
  }

  private static func formatSensitivity(_ sensitivity: Float) -> String {
    return "\(Int(roundSensitivity(sensitivity) * 100))%"
  }
}
