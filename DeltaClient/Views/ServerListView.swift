//
//  ServerListView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 11/12/20.
//

import SwiftUI

struct ServerListView: View {
  @ObservedObject var viewState: ViewState<AppViewStateEnum>
  @ObservedObject var serverList: ServerList
  
  var body: some View {
    NavigationView {
      List {
        Text("Servers")
          .font(.title)
        
        let pingers = serverList.pingers
        ForEach(pingers, id:\.self) { pinger in
          NavigationLink(destination: ServerDetailView(viewState: viewState, pinger: pinger)) {
            ServerListEntryView(pinger: pinger)
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


