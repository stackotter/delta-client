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
  
  @State private var alertMessage = ""
  @State private var showAlert = false
  
  func logoutAll() {
    configManager.logoutAll()
    viewState.update(to: .login, returnTo: .serverList)
  }
  
  func getAccounts() -> [(type: AccountType, account: Account)] {
    let offlineAccounts = configManager.getOfflineAccounts()
    let mojangAccounts = configManager.getMojangAccounts()
    var accounts: [(type: AccountType, account: Account)] = []
    
    for account in offlineAccounts {
      accounts.append((type: AccountType.offline, account: account))
    }
    for account in mojangAccounts {
      accounts.append((type: AccountType.mojang, account: account))
    }
    
    return accounts
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Spacer()
      
      let accounts = getAccounts()
      let selectedAccount = configManager.getSelectedAccount()
      let selectedAccountType = configManager.getSelectedAccountType()
      
      List(accounts.indices, id: \.self) { index in
        let accountInfo = accounts[index]
        let account = accountInfo.account
        let type = accountInfo.type
        let isSelected = selectedAccount?.id == account.id && selectedAccountType == type
        
        HStack {
          // selection indicator
          if isSelected {
            Image(systemName: "chevron.right")
              .frame(width: 20)
          } else {
            Text("")
              .frame(width: 20)
          }
          
          // account name and type
          VStack(alignment: .leading) {
            Text(account.name)
              .font(.title)
            Text("\(type.rawValue) account")
          }
          Spacer()
          
          // actions
          VStack(alignment: .trailing, spacing: 4) {
            Button("remove") {
              configManager.removeAccount(uuid: account.id, type: type)
            }
            Button("select") {
              configManager.selectAccount(uuid: account.id, type: type)
            }.disabled(isSelected)
          }
          
          // make centred (because of chevron)
          Text("")
            .frame(width: 20)
        }.padding(.horizontal, 20)
      }
    }
    .frame(width: 380)
    .navigationTitle("Account Settings")
    .toolbar(content: {
      Button("logout all") {
        logoutAll()
      }
      Button("add account") {
        viewState.update(to: .login)
      }
      Button("done") {
        if configManager.getSelectedAccount() != nil {
          viewState.update(to: .serverList)
        } else {
          alertMessage = "Please select an account"
          showAlert = true
        }
      }.alert(isPresented: $showAlert, content: {
        Alert(title: Text("Account Error"), message: Text(alertMessage), dismissButton: .default(Text("Ok")))
      })
    })
  }
}
