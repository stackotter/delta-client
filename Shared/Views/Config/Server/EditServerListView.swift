//
//  EditServerListView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 7/7/21.
//

import SwiftUI
import DeltaCore
import Combine

struct EditServerListView: View {
  @EnvironmentObject var appState: StateWrapper<AppState>
  
  @State var servers = ConfigManager.default.config.servers
  
  var body: some View {
    EditableList(
      servers,
      itemEditor: ServerEditorView.self,
      itemLabel: { item in
        Text("\(item.name)")
          .font(.headline)
        Text("\(item.description)")
          .font(.subheadline)
      },
      completion: { editedServers in
        var config = ConfigManager.default.config
        config.servers = editedServers
        ConfigManager.default.setConfig(to: config)
        appState.pop()
      },
      cancelation: {
        appState.pop()
      }
    )
    .padding()
    .navigationTitle("Edit Servers")
  }
}
