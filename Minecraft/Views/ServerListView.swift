//
//  ServerListView.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 11/12/20.
//

import SwiftUI

struct ServerListView: View {
  @Binding var isPlaying: Bool
  @Binding var selectedServer: Server?
  
  @ObservedObject var serverList: ServerList
  
  var body: some View {
    NavigationView {
      List {
        Text("Servers")
          .font(.title)
        
        ForEach(serverList.servers, id:\.self) { server in
          NavigationLink(destination: ServerDetailView(isPlaying: $isPlaying, selectedServer: $selectedServer, server: server)) {
            ServerListEntryView(server: server)
          }
        }
        
        Spacer()
        Button(action: {
          serverList.refresh()
        }) {
          Text("Refresh")
        }
      }
      .listStyle(SidebarListStyle())
    }
    .navigationViewStyle(DoubleColumnNavigationViewStyle())
  }
}


