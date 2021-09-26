//
//  VideoSettingsView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 8/7/21.
//

import SwiftUI
import DeltaCore

struct VideoSettingsView: View {
  /// Config updates are sent straight to the event bus as soon as they are made if event bus is present.
  var eventBus: EventBus?
  
  @State var renderDistance: Double = 0
  @State var fov: Double = 0
  
  init(eventBus: EventBus? = nil) {
    self.eventBus = eventBus
  }
  
  /// Handle when user stops/starts editing.
  func onEditingChanged(_ newValue: Bool) {
    // If the user has stopped editing, update config
    if newValue == false {
      save()
    }
  }
  
  /// Save the user's choices to the config file.
  func save() {
    let renderDistance = Int(self.renderDistance)
    let fov = Int(self.fov.rounded())
    
    var config = ConfigManager.default.config
    config.video.renderDistance = renderDistance
    config.video.fov = fov
    ConfigManager.default.setConfig(to: config)
  }
  
  var body: some View {
    ScrollView {
      HStack {
        Text("Render distance: \(Int(renderDistance))")
        Spacer()
        Slider(value: $renderDistance.onChange { newValue in
          let event = ChangeRenderDistanceEvent(renderDistance: Int(newValue))
          eventBus?.dispatch(event)
        }, in: 1...20, step: 1, onEditingChanged: onEditingChanged)
          .frame(width: 220)
      }
      
      HStack {
        Text("FOV: \(Int(fov.rounded()))")
        Spacer()
        Slider(value: $fov.onChange { newValue in
          let event = ChangeFOVEvent(fovDegrees: Int(newValue.rounded()))
          eventBus?.dispatch(event)
        }, in: 30...110, onEditingChanged: onEditingChanged)
          .frame(width: 220)
      }
    }
    .frame(width: 400)
    .navigationTitle("Video")
    .onAppear {
      let config = ConfigManager.default.config
      renderDistance = Double(config.video.renderDistance)
      fov = Double(config.video.fov)
    }
  }
}
