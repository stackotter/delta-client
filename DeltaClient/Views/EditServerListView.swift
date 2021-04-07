//
//  AddServerView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 7/4/21.
//

import SwiftUI
import os

struct EditServerListView: View {
  @ObservedObject var configManager: ConfigManager
  var viewState: ViewState<AppViewState>
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Spacer()
      let servers = configManager.getServers()
      List(servers.indices, id: \.self) { index in
        let descriptor = servers[index]
        VStack {
          if index == 0 {
            Divider()
          }
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text(descriptor.name)
                .font(.title)
              Text("\(descriptor.host)\(descriptor.port != 25565 ? ":\(descriptor.port)" : "")")
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
              Button("remove") {
                configManager.removeServer(at: index)
              }
              Button("edit") {
                viewState.update(to: .editServer(index))
              }
            }
          }
          .padding(4)
          Divider()
        }
      }
    }
    .frame(width: 300)
    .navigationTitle("Edit Server List")
    .toolbar(content: {
      Button("add server") {
        viewState.update(to: .addServer(previousState: .editServerList))
      }
      Button("done") {
        viewState.update(to: .serverList)
      }
    })
  }
}
