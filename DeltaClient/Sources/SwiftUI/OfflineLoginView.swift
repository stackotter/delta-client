//
//  OfflineLoginView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 15/5/21.
//

import SwiftUI

struct OfflineLoginView: View {
  var configManager: ConfigManager
  var viewState: ViewState<AppViewState>
  
  @State var username = ""
  
  func addAccount() {
    let account = OfflineAccount(username: username)
    configManager.addOfflineAccount(account)
    configManager.selectAccount(uuid: account.id, type: .offline)
    viewState.returnToPrevious()
  }
  
  var body: some View {
    Group {
      VStack(spacing: 8) {
        TextField("username", text: $username)
        Button("add") {
          addAccount()
        }
      }
    }
    .frame(width: 150)
    .navigationTitle("Add Offline Account")
    .toolbar {
      Button("cancel") {
        viewState.returnToPrevious()
      }
    }
  }
}
