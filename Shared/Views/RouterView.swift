//
//  RouterView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 19/6/21.
//

import SwiftUI
import DeltaCore

struct RouterView: View {
  @EnvironmentObject var appState: StateWrapper<AppState>
  @EnvironmentObject var configManager: ConfigManager
  
  var body: some View {
    switch appState.current {
      case .launch:
        LoadingView()
      case .playServer(let descriptor):
        PlayServerView(serverDescriptor: descriptor)
      case .serverList:
        ServerListView(serverList: configManager.getServerPingerList())
      case .error(let message):
        DismissibleErrorView(message: message)
      case .fatalError(let message):
        FatalErrorView(message: message)
    }
  }
}
