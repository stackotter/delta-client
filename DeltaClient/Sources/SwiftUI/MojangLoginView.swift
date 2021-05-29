//
//  MojangLoginView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 15/5/21.
//

import SwiftUI

struct MojangLoginView: View {
  var configManager: ConfigManager
  var viewState: ViewState<AppViewState>
  
  @State var email = ""
  @State var password = ""
  
  func login() {
    let clientToken = configManager.getClientToken()
    
    MojangAPI.login(
      email: email,
      password: password,
      clientToken: clientToken,
      onCompletion: { response in
        let account = MojangAccount(
          id: response.user.id,
          email: response.user.username,
          accessToken: response.accessToken,
          profiles: response.availableProfiles,
          selectedProfile: response.selectedProfile.id
        )
        configManager.addMojangAccount(account)
        configManager.selectAccount(uuid: account.id, type: .mojang)
        viewState.returnToPrevious()
      },
      onFailure: { error in
        DeltaClientApp.triggerError("failed to add mojang account: \(error)")
      })
  }
  
  var body: some View {
    VStack(alignment: .center, spacing: 16) {
      VStack(spacing: 8) {
        TextField("email", text: $email)
        SecureField("password", text: $password)
      }
      Button("login") {
        login()
      }
    }
    .frame(width: 200)
    .navigationTitle("Add Mojang Account")
    .toolbar {
      Button("cancel") {
        viewState.returnToPrevious()
      }
    }
  }
}
