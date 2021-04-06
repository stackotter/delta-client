//
//  AppView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 12/1/21.
//

import SwiftUI

enum AppViewStateEnum {
  case playing(withRendering: Bool, serverDescriptor: ServerDescriptor)
  case serverList(serverList: ServerList)
  case login
}

struct AppView: View {
  @ObservedObject var state: ViewState<AppViewStateEnum>
  var managers: Managers
  
  init(managers: Managers) {
    self.managers = managers
    
    let serverList = self.managers.configManager.getServerList()
    serverList.refresh()
    if self.managers.configManager.getHasLoggedIn() {
      self.state = ViewState(initialState: .serverList(serverList: serverList))
    } else {
      self.state = ViewState(initialState: .login)
    }
  }
  
  func login(_ email: String, _ password: String) {
    let clientToken = managers.configManager.getClientToken()
    MojangAPI.login(email: email, password: password, clientToken: clientToken, completion: { response in
      managers.configManager.setUser(
        account: response.user,
        profiles: response.availableProfiles,
        selectedProfile: response.selectedProfile.id
      )
      DispatchQueue.main.sync {
        self.state.update(to: .serverList(serverList: managers.configManager.getServerList()))
      }
    })
  }
  
  var body: some View {
    switch state.state {
      case .login:
        LoginView(callback: login)
      case .playing(let withRendering, let serverDescriptor):
        if withRendering {
          GameRenderView(serverDescriptor: serverDescriptor, managers: managers)
        } else {
          GameCommandView(serverDescriptor: serverDescriptor, managers: managers)
        }
      case .serverList(let serverList):
        ServerListView(viewState: state, serverList: serverList)
    }
  }
}
