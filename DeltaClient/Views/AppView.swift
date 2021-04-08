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
  case addServer(previousState: AddServerPreviousState)
  case editServer(_ index: Int)
  case playing(withRendering: Bool, serverDescriptor: ServerDescriptor)
}

struct AppView: View {
  @ObservedObject var state: ViewState<AppViewState>
  var managers: Managers
  
  init(managers: Managers) {
    self.managers = managers
    
    let serverList = self.managers.configManager.getServerList()
    serverList.refresh()
    if self.managers.configManager.getHasLoggedIn() {
      self.state = ViewState(initialState: .serverList)
    } else {
      self.state = ViewState(initialState: .login)
    }
    
    self.managers.eventManager.registerEventHandler(handleEvent)
  }
  
  func handleEvent(_ event: EventManager.Event) {
    switch event {
      case .leaveServer:
        state.update(to: .serverList)
      case .shouldLogout:
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
      case .addServer(let previousState):
        AddServerView(configManager: managers.configManager, viewState: state, previousState: previousState)
      case .editServer(let index):
        EditServerView(configManager: managers.configManager, viewState: state, serverIndex: index)
      case .playing(let withRendering, let serverDescriptor):
        if withRendering {
          GameRenderView(serverDescriptor: serverDescriptor, managers: managers)
        } else {
          GameCommandView(serverDescriptor: serverDescriptor, managers: managers)
        }
    }
  }
}
