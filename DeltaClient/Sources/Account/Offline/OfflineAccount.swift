//
//  OfflineAccount.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 15/5/21.
//

import Foundation

struct OfflineAccount: Account {
  var id: String
  var profiles: [String: Profile]
  var selectedProfile: String
  
  init(
    profiles: [String: Profile],
    selectedProfile: String)
  {
    let username = profiles[selectedProfile]?.name ?? "error"
    let generatedUUID = UUID.fromString("OfflinePlayer: \(username)")?.uuidString
    
    id = generatedUUID ?? UUID().uuidString
    
    self.profiles = profiles
    self.selectedProfile = selectedProfile
  }
}
