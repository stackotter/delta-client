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

  #if os(tvOS)
  @Namespace var focusNamespace
  #endif

  @EnvironmentObject var modal: Modal
  @EnvironmentObject var appState: StateWrapper<AppState>

  @State var state: MicrosoftState = .authorizingDevice

  @Binding var loginViewState: LoginViewState
  #if os(tvOS)
  @Environment(\.resetFocus) var resetFocus
  #endif

  var completionHandler: (Account) -> Void

  var body: some View {
    VStack {
      switch state {
        case .authorizingDevice:
          Text("Fetching device authorization code")
        case .login(let response):
          Text(response.message)

          #if !os(tvOS)
            Link("Open in browser", destination: response.verificationURI)
              .padding(10)

            Button("Copy code") {
              Clipboard.copy(response.userCode)
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(width: 200)
            .padding(.bottom, 26)
          #endif

          Button("Done") {
            state = .authenticatingUser
            authenticate(with: response.deviceCode)
          }
          .buttonStyle(PrimaryButtonStyle())
          #if !os(tvOS)
          .frame(width: 200)
          #else
          .onAppear {
            resetFocus(in: focusNamespace)
          }
          #endif
        case .authenticatingUser:
          Text("Authenticating...")
      }

      Button("Cancel") {
        loginViewState = .chooseAccountType
      }
      .buttonStyle(SecondaryButtonStyle())
      #if !os(tvOS)
      .frame(width: 200)
      #endif
    }
    .onAppear {
      authorizeDevice()
    }
    #if os(tvOS)
    .focusScope(focusNamespace)
    #endif
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
