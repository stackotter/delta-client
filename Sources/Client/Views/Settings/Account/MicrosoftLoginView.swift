import SwiftUI
import DeltaCore

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

enum MicrosoftState {
  case authorizingDevice
  case login(MicrosoftDeviceAuthorizationResponse)
  case authenticatingUser
}

struct MicrosoftLoginView: View {
  @ObservedObject var loginViewState: StateWrapper<LoginViewState>
  var completionHandler: (Account) -> Void

  @StateObject private var state = StateWrapper<MicrosoftState>(initial: .authorizingDevice)

  var body: some View {
    VStack {
      switch state.current {
        case .authorizingDevice:
          Text("Fetching device authorization code")
        case .login(let response):
          Text(response.message)
          Link("Open in browser", destination: response.verificationURI)
            .padding(10)
          Button("Copy code") {
            #if os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(response.userCode, forType: .string)
            #elseif os(iOS)
            UIPasteboard.general.string = response.userCode
            #else
            #error("Unsupported platform, unknown clipboard implementation")
            #endif
          }
          .buttonStyle(PrimaryButtonStyle())
          .frame(width: 200)
          .padding(.bottom, 10)

          Spacer().frame(height: 16)

          Button("Done") {
            state.update(to: .authenticatingUser)
            authenticate(with: response)
          }
          .buttonStyle(PrimaryButtonStyle())
          .frame(width: 200)
        case .authenticatingUser:
          Text("Authenticating...")
      }

      Button("Cancel") {
        loginViewState.update(to: .chooseAccountType)
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
        state.update(to: .login(response))
      } catch {
        DeltaClientApp.modalError("Failed to authorize device: \(error)", safeState: .serverList)
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
