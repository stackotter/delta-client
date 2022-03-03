import SwiftUI
import DeltaCore

struct AccountSettingsView: View {
  @State var accounts: [Account] = []
  @State var selectedIndex: Int? = nil

  let saveAction: (() -> Void)?

  init(saveAction: (() -> Void)? = nil) {
    self.saveAction = saveAction
  }

  var body: some View {
    VStack {
      EditableList(
        $accounts.onChange(save),
        selected: $selectedIndex.onChange(saveSelected),
        itemEditor: AccountLoginView.self,
        row: row,
        saveAction: saveAction,
        cancelAction: nil,
        emptyMessage: "No accounts",
        title: "Account settings")
    }
    .navigationTitle("Accounts")
    .onAppear {
      accounts = Array(ConfigManager.default.config.accounts.values)
      selectedIndex = getSelectedIndex()
    }
  }

  func row(item: Account, selected: Bool, isFirst: Bool, isLast: Bool, handler: @escaping (EditableListAction) -> Void) -> some View {
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
  }

  /// Saves the given accounts to the config file.
  func save(_ accounts: [Account]) {
    let accountId = getSelectedAccount()?.id

    // Filter out duplicate accounts
    var uniqueAccounts: [Account] = []
    for account in accounts {
      if !uniqueAccounts.contains(where: { $0.id == account.id }) {
        uniqueAccounts.append(account)
      }
    }

    selectedIndex = uniqueAccounts.firstIndex { $0.id == accountId }

    if accounts.count != uniqueAccounts.count {
      self.accounts = uniqueAccounts
      return // Updating accounts will run this function again so we just stop here
    }

    ConfigManager.default.setAccounts(uniqueAccounts, selected: accountId)
  }

  /// Updates the selected account in the config file.
  func saveSelected(_ index: Int?) {
    ConfigManager.default.selectAccount(getSelectedAccount()?.id)
  }

  /// Returns the currently selected account if any.
  func getSelectedAccount() -> Account? {
    guard let selectedIndex = selectedIndex else {
      return nil
    }

    guard selectedIndex >= 0 && selectedIndex < accounts.count else {
      self.selectedIndex = nil
      return nil
    }

    return accounts[selectedIndex]
  }

  /// Returns the index of the currently selected account according to the current configuration.
  func getSelectedIndex() -> Int? {
    guard let selectedAccountId = ConfigManager.default.config.selectedAccountId else {
      return nil
    }

    return accounts.firstIndex { account in
      account.id == selectedAccountId
    }
  }
}
