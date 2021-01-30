//
//  GameView.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 11/12/20.
//

import SwiftUI

struct GameView: View {
  var config: Config
  var client: Client
  
  init(serverInfo: ServerInfo, config: Config, eventManager: EventManager) {
    self.config = config
    self.client = Client(eventManager: eventManager, serverInfo: serverInfo, config: config)
    
    self.client.play()
  }
  
  var body: some View {
    VStack {
      Text("Playing Game! :)")
    }
  }
}
