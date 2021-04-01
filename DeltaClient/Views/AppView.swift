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
