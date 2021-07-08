//
//  PlayServerView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 19/6/21.
//

import SwiftUI
import DeltaCore

enum PlayState {
  case downloadingTerrain
  case playing
}

class PlayStateObject {
  var client: Client
  
  init(client: Client) {
    self.client = client
  }
}

struct PlayServerView: View {
  @EnvironmentObject var appState: StateWrapper<AppState>
  
  @ObservedObject var state = StateWrapper<PlayState>(initial: .downloadingTerrain)
  
  var serverDescriptor: ServerDescriptor
  var client: Client
  
  init(serverDescriptor: ServerDescriptor, registry: Registry) {
    self.serverDescriptor = serverDescriptor
    
    client = Client(registry: registry)
    client.eventBus.registerHandler(handleClientEvent)
    
    joinServer()
  }
  
  func joinServer() {
    guard let account = ConfigManager.default.config.selectedAccount else {
      log.error("Error, attempted to join server without a selected account.")
      DeltaClientApp.modalError("Please login and select an account before joining a server", safeState: .accounts)
      return
    }
    
    ConfigManager.default.refreshSelectedAccount(onCompletion: { account in
      client.joinServer(
        describedBy: serverDescriptor,
        with: account,
        onFailure: { error in
          log.error("Failed to join server: \(error)")
          DeltaClientApp.modalError("Failed to join server: \(error)", safeState: .serverList)
        })
    }, onFailure: { error in
      let message = "Failed to refresh Mojang account '\(account.username)': \(error)"
      log.error(message)
      DeltaClientApp.modalError(message, safeState: .serverList)
    })
  }
  
  func handleClientEvent(_ event: Event) {
    switch event {
      case _ as TerrainDownloadCompletionEvent:
        state.update(to: .playing)
      case let disconnectEvent as PlayDisconnectEvent:
        DeltaClientApp.modalError("Disconnected from server: \(disconnectEvent.reason)", safeState: .serverList)
      case let disconnectEvent as LoginDisconnectEvent:
        DeltaClientApp.modalError("Disconnected from server: \(disconnectEvent.reason)", safeState: .serverList)
      default:
        break
    }
  }
  
  func disconnect() {
    client.leave()
    appState.update(to: .serverList)
  }
  
  var body: some View {
    Group {
      switch state.current {
        case .downloadingTerrain:
          Text("Downloading terrain..")
          Button("Cancel", action: disconnect)
        case .playing:
          MetalView(client: client)
            .toolbar(content: {
              Button("Leave", action: disconnect)
            })
      }
    }
  }
}
