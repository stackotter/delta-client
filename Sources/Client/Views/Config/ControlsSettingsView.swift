import SwiftUI

struct ControlsSettingsView: View {
  @State private var sensitivity: Float = 0
  
  var body: some View {
    let sliderWidth: CGFloat = 400
    let sliderHeight: CGFloat = 25
    ScrollView {
      VStack(spacing: 30) {
        // Mouse sensitivity
        StyledSlider(
          min: 0,
          max: 1000,
          initialValue: sensitivity,
          title: "Sensitivity",
          onDragEnded: { v in
            var config = ConfigManager.default.config
            config.mouseSensitivity = v
            ConfigManager.default.setConfig(to: config)
          }
        )
          .frame(width: sliderWidth, height: sliderHeight)
          .thumbFrame(width: sliderWidth*0.035, height: sliderHeight*1.35)
          .thumbFill(Color.black)
        // Key maps
        InputView { inputCaptured, delegateSetter in
          KeymapEditorView(
            inputCaptured: inputCaptured,
            inputDelegateSetter: delegateSetter
          )
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.vertical, 50)
    .padding(.horizontal, 100)
    .background(Color.black)
    .onAppear {
      sensitivity = ConfigManager.default.config.mouseSensitivity * 100
    }
  }
  
  /// Rounds sensitivity to the nearest even number percentage.
  private static func roundSensitivity(_ sensitivity: Float) -> Float {
    if abs(100 - sensitivity * 100) <= 3 {
      return 1
    }
    return Float(Int(round(sensitivity * 100 / 2)) * 2) / 100
  }
}
