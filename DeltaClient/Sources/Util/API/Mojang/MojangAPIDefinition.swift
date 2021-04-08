//
//  MojangAPIDefinition.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/4/21.
//

import Foundation

struct MojangAPIDefinition {
  static let AUTHENTICATION_URL = URL(string: "https://authserver.mojang.com/authenticate")!
  static let JOIN_SERVER_URL = URL(string: "https://sessionserver.mojang.com/session/minecraft/join")!
  static let REFRESH_URL = URL(string: "https://authserver.mojang.com/refresh")!
  static let BLOCKED_SERVERS_URL = URL(string: "https://sessionserver.mojang.com/blockedservers")!
}
