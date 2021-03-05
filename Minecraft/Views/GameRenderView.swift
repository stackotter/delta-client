//
//  GameRenderView.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 6/3/21.
//

import SwiftUI

struct GameRenderView: View {
  var config: Config
  var client: Client
  
  init(serverInfo: ServerInfo, config: Config, eventManager: EventManager) {
    self.config = config
    self.client = Client(eventManager: eventManager, serverInfo: serverInfo, config: config)
    
    self.client.play()
  }
  
  var body: some View {
    MetalView()
  }
}
