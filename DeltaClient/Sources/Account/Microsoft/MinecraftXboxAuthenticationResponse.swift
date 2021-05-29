//
//  MinecraftXboxAuthenticationResponse.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 24/4/21.
//

import Foundation

struct MinecraftXboxAuthenticationResponse: Codable {
  var username: String
  var roles: [String]
  var accessToken: String
  var tokenType: String
  var expiresIn: Int
  
  private enum CodingKeys: String, CodingKey {
    case username
    case roles
    case accessToken = "access_token"
    case tokenType = "token_type"
    case expiresIn = "expires_in"
  }
}
