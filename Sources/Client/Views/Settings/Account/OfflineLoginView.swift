import SwiftUI
import DeltaCore

struct OfflineLoginView: View {
  @ObservedObject var loginViewState: StateWrapper<LoginViewState>
  var completionHandler: (Account) -> Void
  
  @State private var username = ""
  @State private var errorMessage: String?
  
  var body: some View {
    VStack {
      if let errorMessage = errorMessage {
        Text(errorMessage)
          .foregroundColor(.red)
      }
      
      TextField("Username", text: $username)
      
      HStack {
        Button("Back") {
          loginViewState.update(to: .chooseAccountType)
        }.buttonStyle(SecondaryButtonStyle())
        Button("Login") {
          login()
        }.buttonStyle(PrimaryButtonStyle())
      }
    }
    .frame(width: 200)
  }
  
  func login() {
    guard !username.isEmpty else {
      displayError("Please provide a username")
      return
    }
    
    let account = Account.offline(OfflineAccount(username: username))
    completionHandler(account)
  }
  
  func displayError(_ message: String) {
    ThreadUtil.runInMain {
      errorMessage = message
    }
  }
}
