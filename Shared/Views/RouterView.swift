//
//  RouterView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 19/6/21.
//

import SwiftUI
import DeltaCore

struct RouterView: View {
  @EnvironmentObject var modalState: StateWrapper<ModalState>
  @EnvironmentObject var appState: StateWrapper<AppState>
  @EnvironmentObject var loadingState: StateWrapper<LoadingState>
  
  var body: some View {
    Group {
      switch modalState.current {
        case .none:
          switch loadingState.current {
            case .loading:
              Text("Loading")
                .navigationTitle("Loading")
            case let .loadingWithMessage(message):
              Text(message)
                .navigationTitle("Loading")
            case let .error(message):
              Text(message)
                .navigationTitle("Error")
            case let .done(registry):
              switch appState.current {
                case .serverList:
                  ServerListView()
                case .editServerList:
                  EditServerListView()
                case .accounts:
                  AccountSettingsView(saveAction: {
                    appState.update(to: .serverList)
                  }).padding()
                case .playServer(let descriptor):
                  InputView { inputCaptureEnabled, setDelegate in
                    PlayServerView(serverDescriptor: descriptor, registry: registry, inputCaptureEnabled: inputCaptureEnabled, delegateSetter: setDelegate)
                  }
                case .fatalError(let message):
                  FatalErrorView(message: message)
              }
          }
        case .warning(let message):
          WarningView(message: message)
        case .error(let message, let safeState):
          ErrorView(message: message, safeState: safeState)
      }
    }
  }
}
