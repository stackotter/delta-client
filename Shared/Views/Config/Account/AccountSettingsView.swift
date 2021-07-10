//
//  AccountSettingsView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 8/7/21.
//

import SwiftUI
import DeltaCore

struct AccountSettingsView: View {
  @State var accounts: [Account] = []
  @State var selectedIndex: Int? = nil
  
  let saveAction: (() -> Void)?
  
  init(saveAction: (() -> Void)? = nil) {
    self.saveAction = saveAction
  }
  
  /// Saves the given accounts to the config file.
  func save(_ accounts: [Account]) {
    // Recalculate the index of the selected account
    selectedIndex = getSelectedIndex()
    
    // Filter out duplicate accounts
    var uniqueAccounts: [Account] = []
    for account in accounts {
      let collisions = uniqueAccounts.filter { $0.id == account.id }
      if collisions.count == 0 {
        uniqueAccounts.append(account)
      }
    }
    
    if accounts.count != uniqueAccounts.count {
      self.accounts = uniqueAccounts
      return // Updating accounts will run this function again so we just stop here
    }
    
    var config = ConfigManager.default.config
    
    // Update accounts
    config.updateAccounts(uniqueAccounts)
    
    // Select account
    do {
      try config.selectAccount(getSelectedAccount())
    } catch {
      selectedIndex = nil
    }
    
    ConfigManager.default.setConfig(to: config)
  }
  
  /// Updates the selected account in the config file.
  func saveSelected(_ index: Int?) {
    var config = ConfigManager.default.config
    do {
      try config.selectAccount(getSelectedAccount())
      ConfigManager.default.setConfig(to: config)
    } catch {
      selectedIndex = nil
    }
  }
  
  /// Returns the currently selected account if any.
  func getSelectedAccount() -> Account? {
    if let selectedIndex = selectedIndex {
      if selectedIndex < 0 || selectedIndex >= accounts.count {
        self.selectedIndex = nil
        return nil
      } else {
        return accounts[selectedIndex]
      }
    }
    return nil
  }
  
  func getSelectedIndex() -> Int? {
    return accounts.firstIndex {
      $0.id == ConfigManager.default.config.selectedAccountId
    }
  }
  
  var body: some View {
    VStack {
      EditableList(
        $accounts.onChange(save),
        selected: $selectedIndex.onChange(saveSelected),
        itemEditor: AccountLoginView.self,
        row: { item, selected, isFirst, isLast, handler in
          HStack {
            Image(systemName: "chevron.right")
              .opacity(selected ? 1 : 0)
            
            VStack(alignment: .leading) {
              Text(item.username)
                .font(.headline)
              Text(item.type)
                .font(.subheadline)
            }
            
            Spacer()
            
            Button("Select") { handler(.select) }
              .disabled(selected)
              .buttonStyle(BorderlessButtonStyle())
            IconButton("xmark") { handler(.delete) }
          }
        },
        saveAction: saveAction,
        cancelAction: nil,
        emptyMessage: "No accounts")
    }
    .navigationTitle("Accounts")
    .onAppear {
      accounts = ConfigManager.default.config.accounts
      
      selectedIndex = getSelectedIndex()
    }
  }
}
