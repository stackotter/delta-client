//
//  AccountSettingsView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 29/5/21.
//

import SwiftUI

struct AccountSettingsView: View {
  @ObservedObject var configManager: ConfigManager
  var viewState: ViewState<AppViewState>
  
  func logoutAll() {
    configManager.logoutAll()
    viewState.update(to: .login, returnTo: .serverList)
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Spacer()
      let accounts = configManager.getAccounts()
      List([AccountIdentifier](accounts.keys), id: \.self) { key in
        
      }
    }
    .frame(width: 300)
    .navigationTitle("Edit Server List")
    .toolbar(content: {
      Button("logout all") {
        logoutAll()
      }
      Button("add account") {
        viewState.update(to: .login)
      }
      Button("done") {
        viewState.update(to: .serverList)
      }
    })
  }
}
