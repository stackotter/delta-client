//
//  AppView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 12/1/21.
//

import SwiftUI

enum AppViewState {
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
    
    let serverList = self.managers.configManager.getServerList()
    serverList.refresh()
    if !managers.configManager.getHasLoggedIn() {
      state.update(to: .login)
    }
    
    DeltaClientApp.eventManager.registerEventHandler(handleEvent)
  }
  
  func handleEvent(_ event: AppEvent) {
    switch event {
      case .logout:
        managers.configManager.logout()
        state.update(to: .login)
      default:
        break
    }
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
  }
}
