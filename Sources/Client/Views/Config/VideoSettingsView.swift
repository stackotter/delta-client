import SwiftUI
import DeltaCore

struct VideoSettingsView: View {
  /// Config updates are sent straight to the client as soon as they are made if a client is provided.
  var client: Client?
  
  /// Initial render distance
  @State private var renderDistance: Float = 0
  /// Initial field of view
  @State private var fov: Float = 0
  /// Initial render mode
  @State private var renderMode: RenderMode = .normal
  /// Whether render mode pickable options are displayed or not
  @State private var dropdownExpanded = false
  /// Updated render distance value
  static private var kRenderDistance: Float = 0
  /// Updated field of view value
  static private var kFov: Float = 0
  /// Updated render mode value
  static private var kRenderMode: RenderMode = .normal
  
  
  var config: RenderConfiguration {
    return RenderConfiguration(
      fovY: Float(Self.kFov.rounded()),
      renderDistance: Int(Self.kRenderDistance),
      mode: Self.kRenderMode)
  }
  
  /// - Parameter client: If present, config updates are sent to this client.
  init(client: Client? = nil) {
    self.client = client
  }
  
  /// Saves updated config
  func saveConfig() {
    client?.configuration.render = config
    var config = ConfigManager.default.config
    config.render = self.config
    ConfigManager.default.setConfig(to: config)
  }
  
  var body: some View {
    let hPadding: CGFloat = 100
    let dropdownHeight: CGFloat = 30
    
    ScrollView() {
      VStack(spacing: 30) {
        // Render distance
        buildSlider(
          min: 0,
          max: 32,
          initial: renderDistance,
          title: "Render distance",
          onValueChanged: { v in
            Self.kRenderDistance = v
            saveConfig()
          }
        )
        // Field of view
        buildSlider(
          min: 30,
          max: 110,
          initial: fov,
          title: "Field of view") { v in
            Self.kFov = v
            saveConfig()
          }
        // Render mode
        HStack {
          Text("Render mode")
            .font(Font.custom(.worksans, size: 15))
            .foregroundColor(Color.white)
            .position(x: hPadding/2, y: dropdownHeight/2)
          Spacer()
          StyledDropdown(
            title: renderMode.rawValue,
            placeholder: "Pick a render mode...",
            isExpaned: $dropdownExpanded,
            pickables: RenderMode.allCases.map({ $0.rawValue }),
            onSelection: { index in
              Self.kRenderMode = RenderMode.allCases[index]
              saveConfig()
              dropdownExpanded = false
            }
          )
            .dropdownFrame(width: 200, height: dropdownHeight)
            .padding(.trailing, 16)
        }
        .frame(width: 400)
        .padding(.top, 15)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.vertical, 50)
    .padding(.horizontal, hPadding)
    .background(Color.black)
    .onAppear {
      let config = ConfigManager.default.config.render
      renderDistance = Float(config.renderDistance)
      fov = config.fovY
      renderMode = config.mode
    }
  }
  
  /// Builds a styled slider
  ///
  /// - Parameters:
  ///   - min: the slider's min value
  ///   - max: the slider's max value
  ///   - initial: the slider's initial value
  ///   - title: the slider's title
  @ViewBuilder private func buildSlider(
    min: Int,
    max: Int,
    initial: Float,
    title: String,
    onValueChanged: @escaping ((Float) -> Void)
  ) -> some View {
    let sliderWidth: CGFloat = 400
    let sliderHeight: CGFloat = 25
    
    StyledSlider(
      min: min,
      max: max,
      initialValue: initial,
      title: title,
      onDragEnded: onValueChanged
    )
      .frame(width: sliderWidth, height: sliderHeight)
      .thumbFrame(width: sliderWidth*0.035, height: sliderHeight*1.35)
      .thumbFill(Color.black)
  }
}
