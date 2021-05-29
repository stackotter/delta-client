//
//  MicrosoftAccessTokenResponse.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 24/4/21.
//

import Foundation

struct MicrosoftAccessTokenResponse: Codable {
  var tokenType: String
  var expiresIn: Int
  var scope: String
  var accessToken: String
  
  private enum CodingKeys: String, CodingKey {
    case tokenType = "token_type"
    case expiresIn = "expires_in"
    case scope
    case accessToken = "access_token"
  }
}
