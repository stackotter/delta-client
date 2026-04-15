import DeltaCore
import SwiftCrossUI

enum SettingsPage {
  case accountList
  case inspectAccount(Account)
  case offlineLogin
  case microsoftLogin
}

class SettingsViewState: Observable {
  @Observed var page = SettingsPage.accountList
}

struct SettingsView: View {
  var returnToServerList: () -> Void

  var state = SettingsViewState()

  var body: some View {
    NavigationSplitView {
      VStack {
        Button("Accounts") {
          state.page = .accountList
        }
        Button("Close") {
          returnToServerList()
        }
      }
      .padding(.trailing, 10)
    } detail: {
      VStack {
        switch state.page {
          case .accountList:
            AccountListView { account in
              state.page = .inspectAccount(account)
            } offlineLogin: {
              state.page = .offlineLogin
            } microsoftLogin: {
              state.page = .microsoftLogin
            }
          case .inspectAccount(let account):
            AccountInspectorView(account: account) {
              ConfigManager.default.selectAccount(account.id)
              state.page = .accountList
            } removeAccount: {
              var accounts = ConfigManager.default.config.accounts
              accounts.removeValue(forKey: account.id)
              if ConfigManager.default.config.selectedAccountId == account.id {
                ConfigManager.default.setAccounts(Array(accounts.values), selected: nil)
              } else {
                ConfigManager.default.setAccounts(
                  Array(accounts.values), selected: ConfigManager.default.config.selectedAccountId)
              }
              state.page = .accountList
            }
          case .offlineLogin:
            OfflineLoginView { account in
              ConfigManager.default.addAccount(account)
              state.page = .accountList
            }
          case .microsoftLogin:
            MicrosoftLoginView { account in
              ConfigManager.default.addAccount(account)
              state.page = .accountList
            }
        }
      }
      .padding(.leading, 10)
    }
  }
}
