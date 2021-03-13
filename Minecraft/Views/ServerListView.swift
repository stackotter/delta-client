//
//  ServerListView.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 11/12/20.
//

import SwiftUI

struct ServerListView: View {
  @ObservedObject var viewState: ViewState
  @ObservedObject var serverList: ServerList
  
  var body: some View {
    NavigationView {
      List {
        Text("Servers")
          .font(.title)
        
        let servers = serverList.servers
        ForEach(servers, id:\.self) { server in
          NavigationLink(destination: ServerDetailView(viewState: viewState, server: server)) {
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


