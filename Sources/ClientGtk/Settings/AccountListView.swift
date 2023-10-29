import SwiftCrossUI
import DeltaCore

struct AccountListView: View {
  var inspectAccount: (Account) -> Void
  var offlineLogin: () -> Void
  var microsoftLogin: () -> Void

  var body: some ViewContent {
    VStack {
      Button("Add offline account") {
        offlineLogin()
      }
      Button("Add Microsoft account") {
        microsoftLogin()
      }

      Text("Selected account: \(ConfigManager.default.config.selectedAccount?.username ?? "none")")

      ScrollView {
        ForEach(Array(ConfigManager.default.config.accounts.values)) { account in
          Button(account.username) {
            inspectAccount(account)
          }
          .padding(.bottom, 5)
        }
      }
    }
  }
}
