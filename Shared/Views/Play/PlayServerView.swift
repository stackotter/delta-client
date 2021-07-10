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

enum OverlayState {
  case menu
  case settings
}

struct PlayServerView: View {
  @EnvironmentObject var appState: StateWrapper<AppState>
  @ObservedObject var state = StateWrapper<PlayState>(initial: .downloadingTerrain)
  @ObservedObject var overlayState = StateWrapper<OverlayState>(initial: .menu)
  
  @Binding var cursorCaptured: Bool
  
  var client: Client
  var inputDelegate: ClientInputDelegate
  
  init(serverDescriptor: ServerDescriptor, registry: Registry, inputCaptureEnabled: Binding<Bool>, delegateSetter setDelegate: (InputDelegate) -> Void) {
    // Link whether the cursor is captured to whether input gets sent to delegate
    _cursorCaptured = inputCaptureEnabled
    
    client = Client(registry: registry)
    inputDelegate = ClientInputDelegate(for: client)
    setDelegate(inputDelegate)
    
    client.eventBus.registerHandler(handleClientEvent)
    
    joinServer(serverDescriptor)
  }
  
  func joinServer(_ descriptor: ServerDescriptor) {
    // Get the account to use
    guard let account = ConfigManager.default.config.selectedAccount else {
      log.error("Error, attempted to join server without a selected account.")
      DeltaClientApp.modalError("Please login and select an account before joining a server", safeState: .accounts)
      return
    }
    
    // Refresh the account (if Mojang) and then join the server
    ConfigManager.default.refreshSelectedAccount(onCompletion: { account in
      client.joinServer(
        describedBy: descriptor,
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
          VStack {
            Text("Downloading terrain..")
            Button("Cancel", action: disconnect)
          }
        case .playing:
          ZStack {
            MetalView(client: client)
              .opacity(cursorCaptured ? 1 : 0.2)
              .onAppear {
                inputDelegate.bind($cursorCaptured.onChange { newValue in
                  // When showing overlay make sure menu is the first view
                  if newValue == false {
                    overlayState.update(to: .menu)
                  }
                })
                // TODO: make a way to pass initial render config to metal view
                client.eventBus.dispatch(ChangeFOVEvent(fovDegrees: ConfigManager.default.config.video.fov))
                
                inputDelegate.captureCursor()
              }
            
            if !cursorCaptured {
              switch overlayState.current {
                case .menu:
                  VStack {
                    Group {
                      Button("Back to game", action: inputDelegate.captureCursor)
                        .keyboardShortcut(.escape, modifiers: [])
                      Button("Settings", action: { overlayState.update(to: .settings) })
                      Button("Disconnect", action: disconnect)
                    }
                    .frame(width: 100)
                  }
                case .settings:
                  InGameSettingsView(eventBus: client.eventBus, onDone: {
                    overlayState.update(to: .menu)
                  })
              }
            }
          }
      }
    }
  }
}
