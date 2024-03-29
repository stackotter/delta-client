import SwiftUI
import DeltaCore

enum MicrosoftLoginViewError: LocalizedError {
  case failedToAuthorizeDevice
  case failedToAuthenticate

  var errorDescription: String? {
    switch self {
      case .failedToAuthorizeDevice:
        return "Failed to authorize device."
      case .failedToAuthenticate:
        return "Failed to authenticate Microsoft account."
    }
  }
}

struct MicrosoftLoginView: View {
  enum MicrosoftState {
    case authorizingDevice
    case login(MicrosoftDeviceAuthorizationResponse)
    case authenticatingUser
  }

  @EnvironmentObject var modal: Modal
  @EnvironmentObject var appState: StateWrapper<AppState>

  @State var state: MicrosoftState = .authorizingDevice

  @Binding var loginViewState: LoginViewState

  var completionHandler: (Account) -> Void

  var body: some View {
    VStack {
      switch state {
        case .authorizingDevice:
          Text("Fetching device authorization code")
        case .login(let response):
          Text(response.message)

          Link("Open in browser", destination: response.verificationURI)
            .padding(10)

          Button("Copy code") {
            Clipboard.copy(response.userCode)
          }
          .buttonStyle(PrimaryButtonStyle())
          .frame(width: 200)
          .padding(.bottom, 10)

          Spacer().frame(height: 16)

          Button("Done") {
            state = .authenticatingUser
            authenticate(with: response.deviceCode)
          }
          .buttonStyle(PrimaryButtonStyle())
          .frame(width: 200)
        case .authenticatingUser:
          Text("Authenticating...")
      }

      Button("Cancel") {
        loginViewState = .chooseAccountType
      }
      .buttonStyle(SecondaryButtonStyle())
      .frame(width: 200)
    }.onAppear {
      authorizeDevice()
    }
  }

  func authorizeDevice() {
    Task {
      do {
        let response = try await MicrosoftAPI.authorizeDevice()
        state = .login(response)
      } catch {
        modal.error(MicrosoftLoginViewError.failedToAuthorizeDevice.becauseOf(error)) {
          appState.update(to: .serverList)
        }
      }
    }
  }

  func authenticate(with deviceCode: String) {
    Task {
      do {
        let accessToken = try await MicrosoftAPI.getMicrosoftAccessToken(deviceCode)
        let account = try await MicrosoftAPI.getMinecraftAccount(accessToken)
        completionHandler(.microsoft(account))
      } catch {
        // We can trust MicrosoftAPIError's messages to be suitably human readable
        let modalError: Error
        if let error = error as? MicrosoftAPIError {
          modalError = error
        } else {
          modalError = MicrosoftLoginViewError.failedToAuthenticate.becauseOf(error)
        }

        modal.error(modalError) {
          appState.update(to: .serverList)
        }
      }
    }
  }
}
