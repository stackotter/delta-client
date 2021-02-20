//
//  Config.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation

// TODO: config should eventually not have optionals
struct Config {
  var minecraftFolder: URL
  var serverList: ServerList
  var launcherProfile: LauncherProfile?
}
