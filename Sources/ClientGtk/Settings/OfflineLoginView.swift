import SwiftCrossUI
import DeltaCore

class OfflineLoginViewState: Observable {
  @Observed var username = ""
  @Observed var error: String?
}

struct OfflineLoginView: View {
  var completionHandler: (Account) -> Void

  var state = OfflineLoginViewState()
  
  var body: some ViewContent {
    VStack {
      TextField("Username", state.$username)

      if let error = state.error {
        Text(error)
      }

      Button("Add account") {
        guard !state.username.isEmpty else {
          state.error = "Please provide a username"
          return
        }

        completionHandler(Account.offline(OfflineAccount(username: state.username)))
      }
    }
  }
}
