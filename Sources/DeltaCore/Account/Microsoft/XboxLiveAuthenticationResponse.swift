//
//  XboxLiveAuthenticationResponse.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 24/4/21.
//

import Foundation

struct XboxLiveAuthenticationResponse: Codable {
  struct Claims: Codable {
    var xui: [XUIClaim]
  }
  
  struct XUIClaim: Codable {
    var userHash: String
    
    // swiftlint:disable nesting
    private enum CodingKeys: String, CodingKey {
      case userHash = "uhs"
    }
    // swiftlint:enable nesting
  }
  
  var issueInstant: String
  var notAfter: String
  var token: String
  var displayClaims: Claims
  
  private enum CodingKeys: String, CodingKey {
    case issueInstant = "IssueInstant"
    case notAfter = "NotAfter"
    case token = "Token"
    case displayClaims = "DisplayClaims"
  }
}
