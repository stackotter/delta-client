//
//  MojangAuthenticationRequest.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/4/21.
//

import Foundation

struct MojangAuthenticationRequest: Encodable {
  var agent: MojangAgent
  var username: String
  var password: String
  var clientToken: String
  var requestUser: Bool
}
