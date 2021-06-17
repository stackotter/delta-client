//
//  MicrosoftAuthView.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 24/4/21.
//

import SwiftUI

enum MicrosoftState {
  case login
  case authenticating
  case done
}

struct MicrosoftAuthView: View {
  @ObservedObject var state = ViewState<MicrosoftState>(initialState: .login)
  
  func processURLChange(_ url: URL) {
    if url.absoluteString.starts(with: MicrosoftAPIDefinition.redirectURL.absoluteString) {
      state.update(to: .authenticating)
      do {
        let code = try MicrosoftAuth.codeFromRedirectURL(url)
        MicrosoftAuth.getMicrosoftAccessToken(authorizationCode: code, onCompletion: { microsoftToken in
          MicrosoftAuth.getXBoxLiveToken(microsoftToken, onCompletion: { xboxLiveToken, userHash in
            MicrosoftAuth.getXSTSToken(xboxLiveToken, onCompletion: { xstsToken in
              MicrosoftAuth.getMinecraftAccessToken(xstsToken, userHash, onCompletion: { minecraftAccessToken in
                MicrosoftAuth.getAttachedLicenses(minecraftAccessToken, onCompletion: { licenses in
                  log.debug("licenses: \(licenses)")
                }, onFailure: { error in
                  DeltaCoreApp.triggerError("Failed to get attached product licenses: \(error)")
                })
              }, onFailure: { error in
                DeltaCoreApp.triggerError("Failed to get minecraft access token from xsts token: \(error)")
              })
            }, onFailure: { error in
              if let error = error as? MicrosoftAuthError {
                switch error {
                  case .xstsAuthenticationFailed(let xstsError):
                    switch xstsError.code {
                      case 2148916233: // no xbox live account
                        DeltaCoreApp.triggerError(
                          "This Microsoft account does not have an attached Xbox Live account (\(xstsError.redirect))")
                      case 2148916238: // child account
                        DeltaCoreApp.triggerError(
                          "Child accounts must first be added to a family (\(xstsError.redirect))")
                      default:
                        DeltaCoreApp.triggerError("Unknown XSTS token error: \(error)")
                    }
                  default:
                    DeltaCoreApp.triggerError("Unknown XSTS token error: \(error)")
                }
              } else {
                DeltaCoreApp.triggerError("Failed to get xsts token from xbox live token: \(error)")
              }
            })
          }, onFailure: { error in
            DeltaCoreApp.triggerError("Failed to get xbox live token from microsoft access token: \(error)")
          })
        }, onFailure: { error in
          DeltaCoreApp.triggerError("Failed to get microsoft access token: \(error)")
        })
      } catch {
        DeltaCoreApp.triggerError("Authorization failed, redirectURL: \(url), error: \(error)")
      }
    }
  }

  var body: some View {
    switch state.value {
      case .login:
        WebView(request: URLRequest(url: MicrosoftAuth.getAuthorizationURL()), urlChangeHandler: processURLChange)
      case .authenticating:
        Text("authenticating")
      case .done:
        Text("done")
    }
  }
}
