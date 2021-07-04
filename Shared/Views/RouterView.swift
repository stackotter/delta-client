//
//  RouterView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 19/6/21.
//

import SwiftUI
import DeltaCore

struct RouterView: View {
  @EnvironmentObject var modalState: StateWrapper<ModalState>
  @EnvironmentObject var appState: StateWrapper<AppState>
  
  var body: some View {
    Group {
      switch modalState.current {
        case .none:
          switch appState.current {
            case .launch:
              LoadingView()
            case .serverList:
              let serverList = ServerPingerList(ConfigManager.default.config.servers)
              ServerListView(serverList: serverList)
            case .playServer(let descriptor):
              PlayServerView(serverDescriptor: descriptor)
            case .fatalError(let message):
              FatalErrorView(message: message)
          }
        case .warning(let message):
          WarningView(message: message)
        case .error(let message, let safeState):
          ErrorView(message: message, safeState: safeState)
      }
    }
  }
}
