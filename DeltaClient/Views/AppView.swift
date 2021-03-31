//
//  AppView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 12/1/21.
//

import SwiftUI

enum AppViewStateEnum {
  case playing(withRendering: Bool, serverInfo: ServerInfo)
  case serverList(serverList: ServerList)
}

struct AppView: View {
  @ObservedObject var state: ViewState<AppViewStateEnum>
  var managers: Managers
  
  init(managers: Managers) {
    self.managers = managers
    
    let serverList = self.managers.configManager.getServerList(managers: self.managers)
    serverList.refresh()
    self.state = ViewState(initialState: .serverList(serverList: serverList))
  }
  
  var body: some View {
    switch state.state {
      case .playing(let withRendering, let serverInfo):
        if withRendering {
          GameRenderView(serverInfo: serverInfo, managers: managers)
        } else {
          GameCommandView(serverInfo: serverInfo, managers: managers)
        }
      case .serverList(let serverList):
        ServerListView(viewState: state, serverList: serverList)
    }
  }
}
