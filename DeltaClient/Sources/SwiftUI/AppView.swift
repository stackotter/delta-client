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
  @ObservedObject var state: ViewState<AppViewState>
  var managers: Managers
  
  init(managers: Managers) {
    self.managers = managers
    
    let serverList = self.managers.configManager.getServerList()
    serverList.refresh()
    
    state = ViewState(initialState: .serverList)
    if !managers.configManager.getHasLoggedIn() {
      state.update(to: .login)
    }
    
    DeltaClientApp.eventManager.registerEventHandler(handleEvent)
  }
  
  func handleEvent(_ event: AppEvent) {
    switch event {
      case .leaveServer:
        state.update(to: .serverList)
      case .logout:
        managers.configManager.logout()
        state.update(to: .login)
      default:
        break
    }
  }
  
  var body: some View {
    switch state.value {
      case .login:
        LoginView(configManager: managers.configManager, viewState: state)
      case .serverList:
        ServerListView(configManager: managers.configManager, viewState: state)
      case .editServerList:
        EditServerListView(configManager: managers.configManager, viewState: state)
      case .addServer:
        AddServerView(configManager: managers.configManager, viewState: state)
      case .editServer(let index):
        EditServerView(configManager: managers.configManager, viewState: state, serverIndex: index)
      case .playing(let withRendering, let serverDescriptor):
        if withRendering {
          GameRenderView(serverDescriptor: serverDescriptor, managers: managers)
        } else {
          GameCommandView(serverDescriptor: serverDescriptor, managers: managers)
        }
      case .accountSettings:
        AccountSettingsView(configManager: managers.configManager, viewState: state)
    }
  }
}
