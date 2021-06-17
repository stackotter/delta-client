//
//  MicrosoftAPIDefinition.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 24/4/21.
//

import Foundation

struct MicrosoftAPIDefinition {
  // swiftlint:disable force_unwrapping
  static let clientId = "00000000402b5328" // this is mojang's client id
  
  static let xstsSandboxId = "RETAIL"
  static let xstsRelyingParty = "rp://api.minecraftservices.com/"
  
  static let redirectURL = URL(string: "ms-xal-\(clientId)://auth")!
  static let authorizationBaseURL = URL(string: "https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize")!
  static let authenticationURL = URL(string: "https://login.live.com/oauth20_token.srf")!
  
  static let xboxLiveAuthenticationURL = URL(string: "https://user.auth.xboxlive.com/user/authenticate")!
  static let xstsAuthenticationURL = URL(string: "https://xsts.auth.xboxlive.com/xsts/authorize")!
  static let minecraftXboxAuthenticationURL = URL(
    string: "https://api.minecraftservices.com/authentication/login_with_xbox")!
  
  static let gameOwnershipURL = URL(string: "https://api.minecraftservices.com/entitlements/mcstore")!
  // swiftlint:enable force_unwrapping
}
