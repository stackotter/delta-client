//
//  MojangAuthenticationResponse.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/4/21.
//

import Foundation

struct MojangAuthenticationResponse: Decodable {
  var user: MojangUser
  var clientToken: String
  var accessToken: String
  var selectedProfile: Profile
  var availableProfiles: [Profile]
}
