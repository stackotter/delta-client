//
//  AppView.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 12/1/21.
//

import SwiftUI

enum AppViewState: Equatable {
  case login
  case serverList
  case editServerList
  case addServer
  case editServer(_ index: Int)
  case playing(withRendering: Bool, serverDescriptor: ServerDescriptor)
  case accountSettings
}

struct AppView: View {
  @StateObject var state = ViewState(initialState: AppViewState.serverList)
  var managers: Managers
  
  init(managers: Managers) {
    self.managers = managers
    
    // TODO: this is a horrible place to refresh the server list
    let serverList = self.managers.configManager.getServerList()
    serverList.refresh()
  }
  
  var body: some View {
    Group {
      switch state.value {
        case .login:
          LoginView()
        case .serverList:
          ServerListView()
        case .editServerList:
          EditServerListView()
        case .addServer:
          AddServerView()
        case .editServer(let index):
          EditServerView(serverIndex: index)
        case .playing(let withRendering, let serverDescriptor):
          if withRendering {
            GameRenderView(serverDescriptor: serverDescriptor, managers: managers)
          } else {
            GameCommandView(serverDescriptor: serverDescriptor, managers: managers)
          }
        case .accountSettings:
          AccountSettingsView()
      }
    }
    .environmentObject(state)
    .environmentObject(managers.configManager)
    .onAppear {
      if state.value == .serverList && !managers.configManager.getHasLoggedIn() {
        state.update(to: .login)
      }
    }
  }
}
