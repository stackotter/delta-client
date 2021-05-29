//
//  LoginView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 7/4/21.
//

import SwiftUI

enum LoginViewState {
  case initial
  case mojang
  case offline
}

struct LoginView: View {
  var configManager: ConfigManager
  var viewState: ViewState<AppViewState>
  
  @ObservedObject var state = ViewState<LoginViewState>(initialState: .initial)
  
  var body: some View {
    Group {
      switch state.value {
        case .initial:
          VStack {
            Button("Mojang") {
              state.update(to: .mojang)
            }
            Button("Offline") {
              state.update(to: .offline)
            }
          }
        case .mojang:
          MojangLoginView(configManager: configManager, viewState: viewState)
        case .offline:
          OfflineLoginView(configManager: configManager, viewState: viewState)
      }
    }
    .frame(width: 200)
    .navigationTitle("Add Account")
    .toolbar {
      if configManager.getHasLoggedIn() {
        Button("cancel") {
          viewState.returnToPrevious()
        }
      } else {
        Text("")
          .frame(width: 10)
      }
    }
  }
}
