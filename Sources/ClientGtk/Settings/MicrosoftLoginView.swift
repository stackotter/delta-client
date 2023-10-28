import SwiftCrossUI
import DeltaCore

enum MicrosoftState {
  case authorizingDevice
  case login(MicrosoftDeviceAuthorizationResponse)
  case authenticatingUser

  case error(String)
}

class MicrosoftLoginViewState: Observable {
  @Observed var state = MicrosoftState.authorizingDevice
}

struct MicrosoftLoginView: View {
  var completionHandler: (Account) -> Void

  var state = MicrosoftLoginViewState()

  public init(_ completionHandler: @escaping (Account) -> Void) {
    self.completionHandler = completionHandler
    authorizeDevice()
  }
  
  var body: some ViewContent {
    VStack {
      switch state.state {
        case .authorizingDevice:
          Text("Fetching device authorization code")
        case .login(let response):
          Text(response.message)
          Button("Done") {
            state.state = .authenticatingUser
            authenticate(with: response)
          }
        case .authenticatingUser:
          Text("Authenticating...")
        case .error(let message):
          Text(message)
      } 
    }
  }

  func authorizeDevice() {
    Task {
      do {
        let response = try await MicrosoftAPI.authorizeDevice()
        state.state = .login(response)
      } catch {
        state.state = .error("Failed to authorize device: \(error)")
      }
    }
  }

  func authenticate(with response: MicrosoftDeviceAuthorizationResponse) {
    Task {
      let account: MicrosoftAccount
      do {
        let accessToken = try await MicrosoftAPI.getMicrosoftAccessToken(response.deviceCode)
        account = try await MicrosoftAPI.getMinecraftAccount(accessToken)
      } catch {
        guard case let .failedToGetXSTSToken(MicrosoftAPIError.xstsAuthenticationFailed(xstsError)) = error as? MicrosoftAPIError else {
          state.state = .error("Failed to authenticate Microsoft account: \(error)")
          return
        }

        // TODO: Add localized descriptions to all authentication related errors
        // XSTS errors are the most common so they get nice user-friendly errors
        switch xstsError.code {
          case 2148916233: // No Xbox Live account
            state.state = .error("This Microsoft account does not have an attached Xbox Live account (\(xstsError.redirect))")
          case 2148916238: // Child account
            state.state = .error("Child accounts must first be added to a family (\(xstsError.redirect))")
          default:
            state.state = .error("Failed to get XSTS token: \(error)")
        }
        return
      }

      completionHandler(Account.microsoft(account))
    }
  }
}
