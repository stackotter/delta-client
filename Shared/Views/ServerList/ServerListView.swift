//
//  ServerListView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 19/6/21.
//

import SwiftUI
import DeltaCore

struct ServerListView: View {
  @StateObject var serverList: ServerPingerList
  
  var body: some View {
    let pingers = serverList.pingers
    Group {
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
        }
        .listStyle(SidebarListStyle())
      }
    }
  }
}
