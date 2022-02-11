import SwiftUI
import DeltaCore

enum MicrosoftState {
  case login
  case authenticating
}

struct MicrosoftLoginView: View {
  @ObservedObject var loginViewState: StateWrapper<LoginViewState>
  var completionHandler: (Account) -> Void
  
  @StateObject private var state = StateWrapper<MicrosoftState>(initial: .login)
  @State private var errorMessage: String?
  
  var body: some View {
    switch state.current {
      case .login:
        if let errorMessage = errorMessage {
          Text(errorMessage)
            .foregroundColor(.red)
        }
        
        WebView(request: URLRequest(url: MicrosoftAPI.getAuthorizationURL()), urlChangeHandler: processURLChange)
      case .authenticating:
        Text("Authenticating...")
    }
    
    Button("Cancel") {
      loginViewState.update(to: .chooseAccountType)
    }
    .buttonStyle(SecondaryButtonStyle())
    .frame(width: 200)
  }
  
  func processURLChange(_ url: URL) {
    Task {
      guard url.absoluteString.starts(with: MicrosoftAPI.redirectURL.absoluteString) else {
        return
      }
      
      state.update(to: .authenticating)
      
      let account: MicrosoftAccount
      do {
        account = try await MicrosoftAPI.getMinecraftAccount(url)
      } catch {
        guard case let .failedToGetXSTSToken(MicrosoftAPIError.xstsAuthenticationFailed(xstsError)) = error as? MicrosoftAPIError else {
          DeltaClientApp.modalError("Failed to authenticate Microsoft account: \(error)", safeState: .serverList)
          return
        }
        
        // TODO: Add localized descriptions to all authentication related errors
        // XSTS errors are the most common so they get nice user-friendly errors
        switch xstsError.code {
          case 2148916233: // No Xbox Live account
            DeltaClientApp.modalError("This Microsoft account does not have an attached Xbox Live account (\(xstsError.redirect))", safeState: .serverList)
          case 2148916238: // Child account
            DeltaClientApp.modalError("Child accounts must first be added to a family (\(xstsError.redirect))", safeState: .serverList)
          default:
            DeltaClientApp.modalError("Failed to get XSTS token: \(error)", safeState: .serverList)
        }
        return
      }
      
      completionHandler(Account.microsoft(account))
    }
  }
}
