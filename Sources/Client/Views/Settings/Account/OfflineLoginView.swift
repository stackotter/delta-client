import SwiftUI
import DeltaCore

struct OfflineLoginView: View {
  @State private var username = ""
  @State private var errorMessage: String?
  
  @Binding var loginViewState: LoginViewState

  var completionHandler: (Account) -> Void
  
  var body: some View {
    VStack {
      if let errorMessage = errorMessage {
        Text(errorMessage)
          .foregroundColor(.red)
      }
      
      TextField("Username", text: $username)
      
      HStack {
        Button("Back") {
          loginViewState = .chooseAccountType
        }.buttonStyle(SecondaryButtonStyle())
        Button("Login") {
          login()
        }.buttonStyle(PrimaryButtonStyle())
      }
    }
    #if !os(tvOS)
    .frame(width: 200)
    #endif
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
