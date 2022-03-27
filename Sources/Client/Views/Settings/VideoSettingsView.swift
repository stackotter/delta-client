import SwiftUI
import DeltaCore

struct VideoSettingsView: View {
  /// Config updates are sent straight to the client as soon as they are made if a client is provided.
  var client: Client?

  @State var renderDistance: Float = 0
  @State var fov: Float = 0
  @State var renderMode: RenderMode = .normal
  @State var enableOrderIndependentTransparency = false
  @State var dropdownExpanded = false

  var config: RenderConfiguration {
    return RenderConfiguration(
      fovY: Float(fov.rounded()),
      renderDistance: Int(renderDistance),
      mode: renderMode,
      enableOrderIndependentTransparency: enableOrderIndependentTransparency
    )
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
  func onEditingEnded(_ newValue: Float) {
    // If the user has stopped editing, update config
    save()
  }

  /// Saves the user's choices to the config file.
  func save() {
    var config = ConfigManager.default.config
    config.render = self.config
    ConfigManager.default.setConfig(to: config)
  }

  var body: some View {
    let hPadding: CGFloat = 100
    let dropdownHeight: CGFloat = 30
    ScrollView {
      VStack(spacing: 30) {
        // Render distance
        buildSlider(
          min: 0,
          max: 32,
          initial: renderDistance,
          title: "Render distance",
          value: $renderDistance.onChange(onValueChanged),
          onEditingEnded: onEditingEnded
        )
        // Field of view
        buildSlider(
          min: 30,
          max: 110,
          initial: fov,
          title: "Field of view",
          value: $fov.onChange(onValueChanged),
          onEditingEnded: onEditingEnded
        )
          
 
        HStack {
          Text("Render mode")
            .font(Font.custom(.worksans, size: 15))
            .foregroundColor(Color.white)
            .position(x: hPadding/2, y: dropdownHeight/2)

          Spacer()

          StyledDropdown(
            title: renderMode.rawValue,
            placeholder: "Pick a render mode...",
            isExpanded: $dropdownExpanded,
            pickables: RenderMode.allCases.map({ $0.rawValue }),
            onSelection: { index in
              renderMode = RenderMode.allCases[index]
              onValueChanged(renderMode)
              save()
              dropdownExpanded = false
            }
          )
            .dropdownFrame(width: 200, height: dropdownHeight)
            .padding(.trailing, 15)
        }

        HStack {
          Text("Order independent transparency")
          Spacer()
          Toggle(
            "Order independent transparency",
            isOn: $enableOrderIndependentTransparency.onChange { newValue in
              onValueChanged(newValue)
              save()
            }
          )
            .labelsHidden()
            .toggleStyle(.switch)
            .frame(width: 220)
        }
      }
    }
      .navigationTitle("Video")
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(.top, 15)
      .padding(.vertical, 50)
      .padding(.horizontal, hPadding)
      .background(Color.black)
      .onAppear {
        let config = ConfigManager.default.config.render
        renderDistance = Float(config.renderDistance)
        fov = config.fovY
        renderMode = config.mode
        enableOrderIndependentTransparency = config.enableOrderIndependentTransparency
      }
  }
  
  /// Builds a styled slider
  @ViewBuilder private func buildSlider(
    min: Int,
    max: Int,
    initial: Float,
    title: String,
    value: Binding<Float>,
    onEditingEnded: @escaping ((Float) -> Void)
  ) -> some View {
    let sliderWidth: CGFloat = 400
    let sliderHeight: CGFloat = 25
    
    StyledSlider(
      min: min,
      max: max,
      initialValue: initial,
      title: title,
      onDragChanged: { newValue in
        value.wrappedValue = newValue
      },
      onDragEnded: onEditingEnded
    )
      .frame(width: sliderWidth, height: sliderHeight)
      .thumbFrame(width: sliderWidth*0.035, height: sliderHeight*1.35)
      .thumbFill(Color.black)
  }
}
