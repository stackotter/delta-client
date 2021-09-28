//
//  OfflineAccount.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 15/5/21.
//

import Foundation

public struct OfflineAccount: Account {
  public var id: String
  public var profileId: String
  public var username: String
  
  public init(username: String) {
    let generatedUUID = UUID.fromString("OfflinePlayer: \(username)")?.uuidString
    id = generatedUUID ?? UUID().uuidString
    profileId = id
    self.username = username
  }
}
