//
//  MicrosoftAPIDefinition.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 24/4/21.
//

import Foundation

public struct MicrosoftAPIDefinition {
  // swiftlint:disable force_unwrapping
  public static let clientId = "00000000402b5328" // This is mojang's client id
  
  public static let xstsSandboxId = "RETAIL"
  public static let xstsRelyingParty = "rp://api.minecraftservices.com/"
  
  public static let redirectURL = URL(string: "ms-xal-\(clientId)://auth")!
  public static let authorizationBaseURL = URL(string: "https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize")!
  public static let authenticationURL = URL(string: "https://login.live.com/oauth20_token.srf")!
  
  public static let xboxLiveAuthenticationURL = URL(string: "https://user.auth.xboxlive.com/user/authenticate")!
  public static let xstsAuthenticationURL = URL(string: "https://xsts.auth.xboxlive.com/xsts/authorize")!
  public static let minecraftXboxAuthenticationURL = URL(string: "https://api.minecraftservices.com/authentication/login_with_xbox")!
  
  public static let gameOwnershipURL = URL(string: "https://api.minecraftservices.com/entitlements/mcstore")!
  // swiftlint:enable force_unwrapping
}
