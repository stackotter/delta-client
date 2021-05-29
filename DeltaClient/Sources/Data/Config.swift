//
//  Config.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/4/21.
//

import Foundation

class Config: Codable {
  var hasLoggedIn: Bool
  var clientToken: String
  var selectedAccount: String?
  var selectedAccountType: String?
  var mojangAccounts: [String: MojangAccount]
  var offlineAccounts: [String: OfflineAccount]
  var servers: [ServerDescriptor]
  
  init(
    hasLoggedIn: Bool,
    clientToken: String,
    selectedAccount: String?,
    selectedAccountType: String?,
    mojangAccounts: [String: MojangAccount],
    offlineAccounts: [String: OfflineAccount],
    servers: [ServerDescriptor])
  {
    self.hasLoggedIn = hasLoggedIn
    self.clientToken = clientToken
    self.selectedAccount = selectedAccount
    self.mojangAccounts = mojangAccounts
    self.offlineAccounts = offlineAccounts
    self.servers = servers
  }

  static func createDefault() -> Config {
    return Config(
      hasLoggedIn: false,
      clientToken: UUID().uuidString, // random uuid
      selectedAccount: nil,
      selectedAccountType: nil,
      mojangAccounts: [:],
      offlineAccounts: [:],
      servers: []
    )
  }
}
