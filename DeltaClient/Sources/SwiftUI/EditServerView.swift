//
//  EditServerView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 7/4/21.
//

import SwiftUI
import os

struct EditServerView: View {
  var configManager: ConfigManager
  var viewState: ViewState<AppViewState>
  var serverIndex: Int
  
  @State var serverName: String
  @State var ip: String
  
  @State var errorMessage: String?
  
  init(configManager: ConfigManager, viewState: ViewState<AppViewState>, serverIndex: Int) {
    self.configManager = configManager
    self.viewState = viewState
    self.serverIndex = serverIndex
    
    // set initial text field values
    let descriptor = self.configManager.getServer(at: self.serverIndex)
    self._serverName = State(wrappedValue: descriptor.name)
    self._ip = State(wrappedValue: "\(descriptor.host):\(descriptor.port)")
  }
  
  func addServer() {
    if serverName.count == 0 {
      errorMessage = "please provide a display name"
    } else if let url = URL(string: "minecraft://\(ip)") {
      if let host = url.host {
        let port = url.port ?? 25565
        if port > UInt16.max {
          errorMessage = "port must be less than \(Int(UInt16.max) + 1)"
        } else {
          let descriptor = ServerDescriptor(name: serverName, host: host, port: UInt16(port))
          configManager.removeServer(at: serverIndex)
          configManager.addServer(descriptor)
          returnToEdit()
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
  
  func returnToEdit() {
    viewState.update(to: .editServerList)
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      TextField("display name", text: $serverName)
      TextField("ip", text: $ip)
      HStack {
        Button("save") {
          addServer()
        }
      }
      if errorMessage != nil {
        Text(errorMessage!)
      }
    }
    .frame(width: 200)
    .navigationTitle("Edit Server")
    .toolbar {
      Button("cancel") {
        returnToEdit()
      }
    }
  }
}
