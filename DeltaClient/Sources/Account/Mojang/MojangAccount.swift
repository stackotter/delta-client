//
//  MojangAccount.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/4/21.
//

import Foundation

struct MojangAccount: Account {
  var id: String
  var profileId: String
  var name: String
  var email: String
  var accessToken: String
  
  init(
    id: String,
    profileId: String,
    name: String,
    email: String,
    accessToken: String)
  {
    self.id = id
    self.profileId = profileId
    self.name = name
    self.email = email
    self.accessToken = accessToken
  }
}
