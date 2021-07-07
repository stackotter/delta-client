//
//  ServerListView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 19/6/21.
//

import SwiftUI
import DeltaCore

struct ServerListView: View {
  @EnvironmentObject var appState: StateWrapper<AppState>
  
  @State var pingers: [Pinger]
  
  init() {
    let servers = ConfigManager.default.config.servers
    
    _pingers = State(initialValue: servers.map { server in
      Pinger(server)
    })
    
    refresh()
  }
  
  func refresh() {
    for pinger in pingers {
      pinger.ping()
    }
  }
  
  var body: some View {
    NavigationView {
      List {
        if !pingers.isEmpty {
          ForEach(pingers, id: \.self) { pinger in
            NavigationLink(destination: ServerPingerDetailView(pinger: pinger)) {
              ServerPingerListItem(pinger: pinger)
            }
          }
        } else {
          Text("no servers")
            .italic()
        }
        
        HStack {
          IconButton("square.and.pencil") {
            appState.update(to: .editServerList)
          }
          IconButton("arrow.clockwise") {
            refresh()
          }
        }
      }
      .listStyle(SidebarListStyle())
    }
  }
}
