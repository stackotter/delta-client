import SwiftUI
import DeltaCore

struct MojangLoginView: View {
  @ObservedObject var loginViewState: StateWrapper<LoginViewState>
  var completionHandler: (Account) -> Void
  
  @State private var isEmailValid = false
  @State private var email = ""
  @State private var password = ""
  
  @State private var errorMessage: String?
  @State private var authenticating = false
  
  var body: some View {
    VStack {
      if authenticating {
        Text("Authenticating...")
      } else {
        if let errorMessage = errorMessage {
          Text(errorMessage)
            .foregroundColor(.red)
        }
        
        EmailField("Email", email: $email, isValid: $isEmailValid)
        SecureField("Password", text: $password)
        
        HStack {
          Button("Back") {
            loginViewState.update(to: .chooseAccountType)
          }.buttonStyle(SecondaryButtonStyle())
          Button("Login") {
            login()
          }.buttonStyle(PrimaryButtonStyle())
        }
      }
    }
    .frame(width: 200)
  }
  
  func login() {
    guard isEmailValid else {
      displayError("Please enter a valid email address")
      return
    }
    
    authenticating = true
    
    let email = email
    let password = password
    let clientToken = ConfigManager.default.config.clientToken
    
    Task {
      do {
        let account = try await MojangAPI.login(email: email, password: password, clientToken: clientToken)
        completionHandler(account)
      } catch {
        displayError("Failed to authenticate: \(error)")
      }
    }
  }
  
  func displayError(_ message: String) {
    ThreadUtil.runInMain {
      errorMessage = message
      authenticating = false
    }
  }
}
