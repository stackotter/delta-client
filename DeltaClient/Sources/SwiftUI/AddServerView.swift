//
//  AddServerView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 7/4/21.
//

import SwiftUI

struct AddServerView: View {
  @EnvironmentObject var configManager: ConfigManager
  @EnvironmentObject var viewState: ViewState<AppViewState>
  
  @State var serverName = ""
  @State var ip = ""
  
  @State private var showAlert: Bool = false
  @State private var alertMessage: String = ""
  
  func addServer() {
    if serverName.isEmpty {
      showAlert("please provide a display name")
    } else if let url = URL(string: "minecraft://\(ip)") {
      if let host = url.host {
        let port = url.port ?? 25565
        if port > UInt16.max {
          showAlert("port must be less than \(Int(UInt16.max) + 1)")
        } else {
          let descriptor = ServerDescriptor(name: serverName, host: host, port: UInt16(port))
          configManager.addServer(descriptor)
          viewState.returnToPrevious()
        }
      } else {
        Logger.error("invalid server ip")
        showAlert("please provide valid ip")
      }
    } else {
      Logger.error("invalid server ip")
      showAlert("please provide valid ip")
    }
  }
  
  func showAlert(_ message: String) {
    alertMessage = message
    showAlert = true
  }
  
  var body: some View {
    VStack(alignment: .center, spacing: 16) {
      VStack(spacing: 8) {
        TextField("display name", text: $serverName)
        TextField("ip", text: $ip)
      }
      Button("add") {
        addServer()
      }
    }
    .frame(width: 200)
    .navigationTitle("Add Server")
    .toolbar {
      Button("cancel") {
        viewState.returnToPrevious()
      }
    }
    .alert(isPresented: $showAlert) {
      Alert(title: Text("Server Error"), message: Text(alertMessage), dismissButton: .default(Text("Ok")))
    }
  }
}
