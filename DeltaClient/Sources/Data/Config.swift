//
//  Config.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/4/21.
//

import Foundation

struct Config: Codable {
  var hasLoggedIn: Bool
  var clientToken: String
  var account: MojangAccount?
  var selectedProfile: String?
  var profiles: [String: MojangProfile]
  var servers: [ServerDescriptor]
  
  static func createDefault() -> Config {
    return Config(
      hasLoggedIn: false,
      clientToken: UUID().uuidString, // random uuid
      account: nil,
      selectedProfile: nil,
      profiles: [:],
      servers: []
    )
  }
}
