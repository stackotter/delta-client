//
//  MojangAPIDefinition.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/4/21.
//

import Foundation

struct MojangAPIDefinition {
  // there really should be a way to make url literals
  // swiftlint:disable force_unwrapping
  static let authenticationURL = URL(string: "https://authserver.mojang.com/authenticate")!
  static let joinServerURL = URL(string: "https://sessionserver.mojang.com/session/minecraft/join")!
  static let refreshURL = URL(string: "https://authserver.mojang.com/refresh")!
  static let blockedServersURL = URL(string: "https://sessionserver.mojang.com/blockedservers")!
  // swiftlint:enable force_unwrapping
}
