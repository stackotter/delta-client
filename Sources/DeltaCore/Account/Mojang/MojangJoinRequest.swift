//
//  MojangJoinRequest.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 7/4/21.
//

import Foundation

struct MojangJoinRequest: Codable {
  var accessToken: String
  var selectedProfile: String
  var serverId: String
}
