import SwiftUI
import DeltaCore

struct MojangLoginView: View {
  @EnvironmentObject var managedConfig: ManagedConfig
  
  @State var isEmailValid = false
  @State var email = ""
  @State var password = ""
  
  @State var errorMessage: String?
  @State var authenticating = false
  
  @Binding var loginViewState: LoginViewState

  var completionHandler: (Account) -> Void

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
            loginViewState = .chooseAccountType
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
    let clientToken = managedConfig.clientToken
    
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
