//
//  AddServerView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 7/4/21.
//

import SwiftUI
import os

enum AddServerPreviousState {
  case serverList
  case editServerList
}

struct AddServerView: View {
  var configManager: ConfigManager
  var viewState: ViewState<AppViewState>
  var previousState: AddServerPreviousState
  
  @State var serverName = ""
  @State var ip = ""
  
  @State var errorMessage: String?
  
  init(configManager: ConfigManager, viewState: ViewState<AppViewState>, previousState: AddServerPreviousState) {
    self.configManager = configManager
    self.viewState = viewState
    self.previousState = previousState
  }
  
  func addServer() {
    if serverName.isEmpty {
      errorMessage = "please provide a display name"
    } else if let url = URL(string: "minecraft://\(ip)") {
      if let host = url.host {
        let port = url.port ?? 25565
        if port > UInt16.max {
          errorMessage = "port must be less than \(Int(UInt16.max) + 1)"
        } else {
          let descriptor = ServerDescriptor(name: serverName, host: host, port: UInt16(port))
          configManager.addServer(descriptor)
          returnToPrevious()
        }
      } else {
        Logger.error("invalid server ip")
        errorMessage = "please provide valid ip"
      }
    } else {
      Logger.error("invalid server ip")
      errorMessage = "please provide valid ip"
    }
  }
  
  func returnToPrevious() {
    switch previousState {
      case .serverList:
        viewState.update(to: .serverList)
      case .editServerList:
        viewState.update(to: .editServerList)
    }
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      TextField("display name", text: $serverName)
      TextField("ip", text: $ip)
      HStack {
        Button("add") {
          addServer()
        }
      }
      if errorMessage != nil {
        Text(errorMessage!)
      }
    }
    .frame(width: 200)
    .navigationTitle("Add Server")
    .toolbar {
      Button("cancel") {
        returnToPrevious()
      }
    }
  }
}
