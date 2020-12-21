//
//  MainView.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 10/12/20.
//

import SwiftUI

// TODO: start using a viewState instead of multiple variables or something
struct MainView: View {
  let serverList: ServerList
  
  @State private var isPlaying = false
  @State private var selectedServer: Server? = nil
  
  var body: some View {
    Group {
      if (!isPlaying) {
        ServerListView(isPlaying: $isPlaying, selectedServer: $selectedServer, serverList: serverList)
      } else {
        GameView(server: selectedServer!)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

struct MainView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      let serverList = ServerList(withServers: [
        Server(name: "HyPixel", host: "play.hypixel.net", port: 25565),
        Server(name: "MinePlex", host: "play.hypixel.net", port: 25565)
      ])
      MainView(serverList: serverList)
    }
  }
}
