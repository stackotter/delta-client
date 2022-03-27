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
            // Account name
            HStack(spacing: 0) {
              Text("\(item.username) • ")
                .font(Font.custom(.worksans, size: 14))
                .foregroundColor(Color.white)
              Text(item.type)
                .font(Font.custom(.worksans, size: 10))
                .foregroundColor(Color.white)
            }
            Spacer()
            Button {  handler(.delete) } label: {
              Image(systemName: "trash")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
          }
          .frame(width: 400, height: 30)
          .padding(.vertical, 5)
          .padding(.horizontal, 15)
          .background(selected ? Color.darkGray : Color.clear)
          .cornerRadius(4)
          .contentShape(Rectangle())
          .onTapGesture { handler(.select) }
        },
        saveAction: saveAction,
        cancelAction: nil,
        emptyMessage: "No accounts",
        title: "Account settings")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.vertical, 50)
    .padding(.horizontal, 100)
    .background(Color.black)
    .onAppear {
      accounts = ConfigManager.default.config.accounts
      selectedIndex = getSelectedIndex()
    }
  }
}
