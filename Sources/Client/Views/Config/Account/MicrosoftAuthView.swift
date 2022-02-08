import SwiftUI
import DeltaCore

enum MicrosoftState {
  case login
  case authenticating
  case done
}

struct MicrosoftAuthView: View {
  @ObservedObject var state = StateWrapper<MicrosoftState>(initial: .login)
  
  var body: some View {
    switch state.current {
      case .login:
        WebView(request: URLRequest(url: MicrosoftAPI.getAuthorizationURL()), urlChangeHandler: processURLChange)
      case .authenticating:
        Text("authenticating")
      case .done:
        Text("done")
    }
  }
  
  func processURLChange(_ url: URL) {
    Task {
      guard url.absoluteString.starts(with: MicrosoftAPI.redirectURL.absoluteString) else {
        return
      }
      state.update(to: .authenticating)
      guard let code = MicrosoftAPI.codeFromRedirectURL(url) else {
        DeltaClientApp.modalError("Failed to get Microsoft OAuth code from the redirect URL", safeState: .serverList)
        return
      }
      
      // Get Microsoft access token
      let microsoftAccessToken: String
      do {
        microsoftAccessToken = try await MicrosoftAPI.getMicrosoftAccessToken(authorizationCode: code)
      } catch {
        DeltaClientApp.modalError("Failed to get microsoft access token: \(error.localizedDescription)", safeState: .serverList)
        return
      }
      
      // Get Xbox live token
      let xboxLiveToken: XboxLiveToken
      do {
        xboxLiveToken = try await MicrosoftAPI.getXBoxLiveToken(microsoftAccessToken)
      } catch {
        DeltaClientApp.modalError("Failed to get xbox live token from microsoft access token: \(error.localizedDescription)", safeState: .serverList)
        return
      }
      
      // Get XSTS token
      let xstsToken: String
      do {
        xstsToken = try await MicrosoftAPI.getXSTSToken(xboxLiveToken.token)
      } catch {
        handleXSTSError(error)
        return
      }
      
      // Get Minecraft access token
      let minecraftAccessToken: String
      do {
        minecraftAccessToken = try await MicrosoftAPI.getMinecraftAccessToken(xstsToken, xboxLiveToken.userHash)
      } catch {
        DeltaClientApp.modalError("Failed to get minecraft access token from xsts token: \(error)", safeState: .serverList)
        return
      }
      
      // Get a list of the user's licenses
      let licenses: [GameOwnershipResponse.License]
      do {
        licenses = try await MicrosoftAPI.getAttachedLicenses(minecraftAccessToken)
      } catch {
        DeltaClientApp.modalError("Failed to get attached product licenses: \(error)", safeState: .serverList)
        return
      }
      
      log.debug("licenses: \(licenses)")
    }
  }
  
  func handleXSTSError(_ error: Error) {
    guard let error = error as? MicrosoftAPIError else {
      DeltaClientApp.modalError("Failed to get XSTS token: \(error)", safeState: .serverList)
      return
    }
    
    switch error {
      case .xstsAuthenticationFailed(let xstsError):
        switch xstsError.code {
          case 2148916233: // No Xbox Live account
            DeltaClientApp.modalError("This Microsoft account does not have an attached Xbox Live account (\(xstsError.redirect))", safeState: .serverList)
          case 2148916238: // Child account
            DeltaClientApp.modalError("Child accounts must first be added to a family (\(xstsError.redirect))", safeState: .serverList)
          default:
            DeltaClientApp.modalError("Failed to get XSTS token: \(error)", safeState: .serverList)
        }
      default:
        DeltaClientApp.modalError("Failed to get XSTS token: \(error)", safeState: .serverList)
    }
  }
}
