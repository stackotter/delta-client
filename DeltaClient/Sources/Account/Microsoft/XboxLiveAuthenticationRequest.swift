//
//  XboxLiveAuthenticationRequest.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 24/4/21.
//

import Foundation

struct XboxLiveAuthenticationRequest: Codable {
  struct Properties: Codable {
    var authMethod: String
    var siteName: String
    var accessToken: String
    
    // swiftlint:disable nesting
    private enum CodingKeys: String, CodingKey {
      case authMethod = "AuthMethod"
      case siteName = "SiteName"
      case accessToken = "RpsTicket"
    }
    // swiftlint:enable nesting
  }
  
  var properties: Properties
  var relyingParty: String
  var tokenType: String
  
  private enum CodingKeys: String, CodingKey {
    case properties = "Properties"
    case relyingParty = "RelyingParty"
    case tokenType = "TokenType"
  }
}
