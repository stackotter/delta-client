//
//  MojangAccount.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/4/21.
//

import Foundation

struct MojangAccount: Codable {
  var id: String
  var email: String
  var accessToken: String
}
