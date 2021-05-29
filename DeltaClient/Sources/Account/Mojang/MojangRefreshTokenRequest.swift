//
//  MojangRefreshTokenRequest.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 24/4/21.
//

import Foundation

struct MojangRefreshTokenRequest: Codable {
  var accessToken: String
  var clientToken: String
}
