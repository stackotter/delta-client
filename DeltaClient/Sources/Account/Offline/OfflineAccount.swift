//
//  OfflineAccount.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 15/5/21.
//

import Foundation

struct OfflineAccount: Account {
  var id: String
  var profileId: String
  var name: String
  
  init(username: String) {
    let generatedUUID = UUID.fromString("OfflinePlayer: \(username)")?.uuidString
    id = generatedUUID ?? UUID().uuidString
    profileId = id
    
    name = username
  }
}
