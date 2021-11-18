import SwiftUI

struct ControlsSettingsView: View {
  @State var sensitivity: Float = ConfigManager.default.config.mouseSensitivity
  
  var body: some View {
    ScrollView {
      HStack {
        Text("Sensitivity: \(Self.formatPercentage(sensitivity))")
          .frame(width: 150)
        
        Slider(value: $sensitivity, in: 0...10, onEditingChanged: { isEditing in
          if !isEditing {
            var config = ConfigManager.default.config
            config.mouseSensitivity = sensitivity
            ConfigManager.default.setConfig(to: config)
          }
        })
      }
      .frame(width: 450)
      
      InputView { inputCaptured, delegateSetter in
        KeymapEditorView(
          inputCaptured: inputCaptured,
          inputDelegateSetter: delegateSetter)
      }
    }
  }
  
  private static func formatPercentage(_ number: Float) -> String {
    let numberFormatter = NumberFormatter()
    numberFormatter.maximumFractionDigits = 0
    guard let string = numberFormatter.string(from: NSNumber(value: number * 100)) else {
      return ""
    }
    return string + "%"
  }
}
