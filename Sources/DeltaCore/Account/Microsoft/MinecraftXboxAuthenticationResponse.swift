//
//  MinecraftXboxAuthenticationResponse.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 24/4/21.
//

import Foundation

public struct MinecraftXboxAuthenticationResponse: Codable {
  public var username: String
  public var roles: [String]
  public var accessToken: String
  public var tokenType: String
  public var expiresIn: Int
  
  private enum CodingKeys: String, CodingKey {
    case username
    case roles
    case accessToken = "access_token"
    case tokenType = "token_type"
    case expiresIn = "expires_in"
  }
}
