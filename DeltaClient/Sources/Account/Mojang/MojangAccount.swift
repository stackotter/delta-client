//
//  MojangAccount.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/4/21.
//

import Foundation

struct MojangAccount: Account {
  var id: String
  var email: String
  var accessToken: String
  var profiles: [String: Profile]
  var selectedProfile: String
  
  init(
    id: String,
    email: String,
    accessToken: String,
    profiles: [Profile],
    selectedProfile: String)
  {
    self.id = id
    self.email = email
    self.accessToken = accessToken
    self.selectedProfile = selectedProfile
    
    var profilesMap: [String: Profile] = [:]
    for profile in profiles {
      profilesMap[profile.id] = profile
    }
    self.profiles = profilesMap
  }
}
