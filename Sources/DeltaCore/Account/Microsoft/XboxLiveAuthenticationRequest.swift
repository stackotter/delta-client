//
//  XboxLiveAuthenticationRequest.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 24/4/21.
//

import Foundation

public struct XboxLiveAuthenticationRequest: Codable {
  public struct Properties: Codable {
    public var authMethod: String
    public var siteName: String
    public var accessToken: String
    
    // swiftlint:disable nesting
    private enum CodingKeys: String, CodingKey {
      case authMethod = "AuthMethod"
      case siteName = "SiteName"
      case accessToken = "RpsTicket"
    }
    // swiftlint:enable nesting
  }
  
  public var properties: Properties
  public var relyingParty: String
  public var tokenType: String
  
  private enum CodingKeys: String, CodingKey {
    case properties = "Properties"
    case relyingParty = "RelyingParty"
    case tokenType = "TokenType"
  }
}
