//
//  AccountLoginView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 8/7/21.
//

import SwiftUI
import DeltaCore

struct AccountLoginView: EditorView {
  typealias Item = Account
  
  @State var accountType = AccountType.mojang
  
  @State var isEmailValid = false
  @State var username = ""
  @State var password = ""
  
  @State var errorMessage: String?
  /// Whether we are waiting for account login to complete or not (e.g. true when contacting Mojang servers).
  @State var loggingIn = false
  
  let completionHandler: (Item) -> Void
  let cancelationHandler: (() -> Void)?
  
  /// Ignores `item` because this is only ever used for logging into account not editing them.
  init(_ item: Item?=nil, completion: @escaping (Item) -> Void, cancelation: (() -> Void)?) {
    completionHandler = completion
    cancelationHandler = cancelation
  }
  
  func login() {
    switch accountType {
      case .mojang:
        if !isEmailValid {
          errorMessage = "Invalid email address"
        } else {
          loggingIn = true
          MojangAPI.login(
            email: username,
            password: password,
            clientToken: ConfigManager.default.config.clientToken,
            onCompletion: completionHandler,
            onFailure: { error in
              ThreadUtil.runInMain {
                errorMessage = "Login failed"
                loggingIn = false
              }
            })
        }
      case .offline:
        let account = OfflineAccount(username: username)
        completionHandler(account)
    }
  }
  
  var body: some View {
    VStack {
      if !loggingIn {
        Picker("Account Type", selection: $accountType) {
          ForEach(AccountType.allCases) { type in
            Text(type.rawValue.capitalized)
              .tag(type)
          }
        }
        .padding(.bottom, 8)
        
        VStack {
          switch accountType {
            case .mojang:
              EmailField("Email", email: $username, isValid: $isEmailValid)
              SecureField("Password", text: $password)
            case .offline:
              TextField("Username", text: $username)
          }
        }
        .padding(.bottom, 8)
        
        if let error = errorMessage {
          Text(error)
            .bold()
        }
        
        HStack {
          if let cancel = cancelationHandler {
            Button("Cancel", action: cancel)
              .buttonStyle(BorderlessButtonStyle())
          }
          Button("Login", action: login)
        }
      } else {
        Text("Logging in..")
      }
    }
    .navigationTitle("Account Login")
    .frame(width: 200)
  }
}
