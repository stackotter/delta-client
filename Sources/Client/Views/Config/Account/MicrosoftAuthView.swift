import SwiftUI
import DeltaCore

enum MicrosoftState {
  case login
  case authenticating
  case done
}

struct MicrosoftAuthView: View {
  @ObservedObject var state = StateWrapper<MicrosoftState>(initial: .login)
  
  func processURLChange(_ url: URL) {
    if url.absoluteString.starts(with: MicrosoftAPI.redirectURL.absoluteString) {
      state.update(to: .authenticating)
      do {
        let code = try MicrosoftAPI.codeFromRedirectURL(url)
        MicrosoftAPI.getMicrosoftAccessToken(authorizationCode: code, onCompletion: { microsoftToken in
          MicrosoftAPI.getXBoxLiveToken(microsoftToken, onCompletion: { xboxLiveToken, userHash in
            MicrosoftAPI.getXSTSToken(xboxLiveToken, onCompletion: { xstsToken in
              MicrosoftAPI.getMinecraftAccessToken(xstsToken, userHash, onCompletion: { minecraftAccessToken in
                MicrosoftAPI.getAttachedLicenses(minecraftAccessToken, onCompletion: { licenses in
                  log.debug("licenses: \(licenses)")
                }, onFailure: { error in
                  DeltaClientApp.modalError("Failed to get attached product licenses: \(error.localizedDescription)", safeState: .serverList)
                })
              }, onFailure: { error in
                DeltaClientApp.modalError("Failed to get minecraft access token from xsts token: \(error.localizedDescription)", safeState: .serverList)
              })
            }, onFailure: { error in
              switch error {
                case .xstsAuthenticationFailed(let xstsError):
                  switch xstsError.code {
                    case 2148916233: // no xbox live account
                      DeltaClientApp.modalError(
                        "This Microsoft account does not have an attached Xbox Live account (\(xstsError.redirect))", safeState: .serverList)
                    case 2148916238: // child account
                      DeltaClientApp.modalError(
                        "Child accounts must first be added to a family (\(xstsError.redirect))", safeState: .serverList)
                    default:
                      DeltaClientApp.modalError("Unknown XSTS token error: \(error.localizedDescription)", safeState: .serverList)
                  }
                default:
                  DeltaClientApp.modalError("Unknown XSTS token error: \(error.localizedDescription)", safeState: .serverList)
              }
            })
          }, onFailure: { error in
            DeltaClientApp.modalError("Failed to get xbox live token from microsoft access token: \(error.localizedDescription)", safeState: .serverList)
          })
        }, onFailure: { error in
          DeltaClientApp.modalError("Failed to get microsoft access token: \(error.localizedDescription)", safeState: .serverList)
        })
      } catch {
        DeltaClientApp.modalError("Authorization failed, redirectURL: \(url), error: \(error.localizedDescription)", safeState: .serverList)
      }
    }
  }
  
  var body: some View {
    switch state.current {
      case .login:
        Text("Microsoft login doesn't work yetide")
        WebView(request: URLRequest(url: MicrosoftAPI.getAuthorizationURL()), urlChangeHandler: processURLChange)
      case .authenticating:
        Text("authenticating")
      case .done:
        Text("done")
    }
  }
}
