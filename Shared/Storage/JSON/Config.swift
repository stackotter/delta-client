//
//  Config.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 2/7/21.
//

import Foundation
import DeltaCore

public struct Config: Codable {
  public var clientToken: String
  public var selectedAccount: String?
  public var selectedAccountType: String?
  public var mojangAccounts: [String: MojangAccount]
  public var offlineAccounts: [String: OfflineAccount]
  public var servers: [ServerDescriptor]
  
  public init() {
    clientToken = UUID().uuidString
    mojangAccounts = [:]
    offlineAccounts = [:]
    servers = []
  }
}
