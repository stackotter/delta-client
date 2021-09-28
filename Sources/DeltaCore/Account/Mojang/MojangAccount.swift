//
//  MojangAccount.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 6/4/21.
//

import Foundation

public struct MojangAccount: Account {
  public var id: String
  public var profileId: String
  public var username: String
  public var email: String
  public var accessToken: String
  
  public init(
    id: String,
    profileId: String,
    name: String,
    email: String,
    accessToken: String
  ) {
    self.id = id
    self.profileId = profileId
    self.username = name
    self.email = email
    self.accessToken = accessToken
  }
}
