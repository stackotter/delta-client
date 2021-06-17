//
//  Config.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 6/4/21.
//

import Foundation

struct Config: Codable {
  var clientToken: String
  var selectedAccount: String?
  var selectedAccountType: String?
  var mojangAccounts: [String: MojangAccount]
  var offlineAccounts: [String: OfflineAccount]
  var servers: [ServerDescriptor]
  
  init(
    clientToken: String,
    selectedAccount: String?,
    selectedAccountType: String?,
    mojangAccounts: [String: MojangAccount],
    offlineAccounts: [String: OfflineAccount],
    servers: [ServerDescriptor])
  {
    self.clientToken = clientToken
    self.selectedAccount = selectedAccount
    self.selectedAccountType = selectedAccountType
    self.mojangAccounts = mojangAccounts
    self.offlineAccounts = offlineAccounts
    self.servers = servers
  }

  static func createDefault() -> Config {
    return Config(
      clientToken: UUID().uuidString, // random uuid
      selectedAccount: nil,
      selectedAccountType: nil,
      mojangAccounts: [:],
      offlineAccounts: [:],
      servers: []
    )
  }
}
