//
//  LoginView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 7/4/21.
//

import SwiftUI

struct LoginView: View {
  var configManager: ConfigManager
  var viewState: ViewState<AppViewState>
  
  @State var email: String = ""
  @State var password: String = ""
  
  func login() {
    let clientToken = configManager.getClientToken()
    MojangAPI.login(email: email, password: password, clientToken: clientToken, completion: { response in
      let account = MojangAccount(
        id: response.user.id,
        email: response.user.username,
        accessToken: response.accessToken
      )
      configManager.setUser(
        account: account,
        profiles: response.availableProfiles,
        selectedProfile: response.selectedProfile.id
      )
      viewState.update(to: .serverList)
    })
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      TextField("email", text: $email)
      SecureField("password", text: $password)
      Button("login") {
        login()
      }
    }
    .frame(width: 200)
    .navigationTitle("Login")
    .toolbar {
      Text("")
        .frame(width: 10)
    }
  }
}
