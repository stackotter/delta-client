import SwiftCrossUI
import DeltaCore

struct AccountInspectorView: View {
  var account: Account

  var selectAccount: () -> Void
  var removeAccount: () -> Void
  
  public init(account: Account, selectAccount: @escaping () -> Void, removeAccount: @escaping () -> Void) {
    self.account = account
    self.selectAccount = selectAccount
    self.removeAccount = removeAccount
  }
  
  var body: some ViewContent {
    VStack {
      Text("Username: \(account.username)")
      Text("Type: \(account.type)")
      
      Button("Select account") {
        selectAccount()
      }
      Button("Remove account") {
        removeAccount()
      }
    }
  }
}
