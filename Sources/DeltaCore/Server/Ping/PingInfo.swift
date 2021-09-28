//
//  PingInfo.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 6/7/21.
//

import Foundation

/// The information about a server received in a ping response.
public struct PingInfo {
  public var versionName: String
  public var protocolVersion: Int
  public var maxPlayers: Int
  public var numPlayers: Int
  public var description: String
  public var modInfo: String
  
  public init(versionName: String, protocolVersion: Int, maxPlayers: Int, numPlayers: Int, description: String, modInfo: String) {
    self.versionName = versionName
    self.protocolVersion = protocolVersion
    self.maxPlayers = maxPlayers
    self.numPlayers = numPlayers
    self.description = description
    self.modInfo = modInfo
  }
}
