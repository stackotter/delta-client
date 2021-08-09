//
//  DirectConnectView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 9/8/21.
//

import SwiftUI
import DeltaCore

struct DirectConnectView: View {
  @EnvironmentObject var appState: StateWrapper<AppState>
  
  @State var host: String = ""
  @State var port: UInt16? = nil
  
  @State var errorMessage: String? = nil
  @State var isAddressValid = false
  
  private func verify() -> Bool {
    if !isAddressValid {
      errorMessage = "Invalid IP"
    } else {
      return true
    }
    return false
  }
  
  var body: some View {
    VStack {
      AddressField("Server address", host: $host, port: $port, isValid: $isAddressValid)
      
      if let message = errorMessage {
        Text(message)
          .bold()
      }
      
      HStack {
        Button("Cancel") {
          appState.update(to: .serverList)
        }
        .buttonStyle(SecondaryButtonStyle())
        
        Button("Connect") {
          if verify() {
            let descriptor = ServerDescriptor(name: "Direct Connect", host: host, port: port)
            appState.update(to: .playServer(descriptor))
          }
        }
        .buttonStyle(PrimaryButtonStyle())
      }
      .padding(.top, 16)
    }
    .frame(width: 200)
  }
}
