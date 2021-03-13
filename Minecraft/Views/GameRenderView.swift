//
//  GameRenderView.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Combine
import SwiftUI

class GameState: ObservableObject {
  @Published var downloadingTerrain = true
  var sink: AnyCancellable?
  var client: Client
  
  init(client: Client) {
    self.client = client
    self.client.managers.eventManager.registerEventHandler({ event in
      print("event received")
      DispatchQueue.main.sync {
        self.downloadingTerrain = false
      }
    }, eventName: "downloadedTerrain")
  }
}

struct GameRenderView: View {
  var config: Config
  let client: Client
  
  @ObservedObject var state: GameState
  
  init(serverInfo: ServerInfo, config: Config, managers: Managers) {
    self.config = config
    self.client = Client(managers: managers, serverInfo: serverInfo, config: config)
    self.state = GameState(client: self.client)
    
    self.client.play()
  }
  
  func updateTerrainStatus(status: Bool) {
    state.downloadingTerrain = status
  }
  
  var body: some View {
    if state.downloadingTerrain {
      Text("downloading terrain")
    } else {
      MetalView(client: client)
    }
  }
}
