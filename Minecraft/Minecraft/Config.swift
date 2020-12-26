//
//  Config.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 14/12/20.
//

import Foundation
import AppKit
import Network
import os

// TODO: Get this working under the sandbox
struct Config {
  var serverList: ServerList
  
  static func from(minecraftFolder: URL, eventManager: EventManager) -> Config {
    let logger = Logger(for: type(of: self))
    let serverList = loadServerList(minecraftFolder: minecraftFolder, eventManager: eventManager)
//    serverList.servers.append(contentsOf: [
//      Server(name: "MinePlex", host: "us.mineplex.com", port: 25565),
//      // TODO: get SRV records working
//      Server(name: "PVPWars", host: "play.pvpwars.net", port: 25565)
//    ])
    logger.debug("loaded server list")
    loadUserProfile(minecraftFolder: minecraftFolder)
    logger.debug("loaded user profile")
    return Config(serverList: serverList)
  }
  
  static func loadServerList(minecraftFolder: URL, eventManager: EventManager) -> ServerList {
    let serversDatURL = minecraftFolder.appendingPathComponent("servers.dat")
    let serversNBT = NBT.fromURL(serversDatURL)
    let serverNBTList = serversNBT.root.nbtData["servers"] as! [[String: String]]
    var servers: [Server] = []
    for serverNBT in serverNBTList {
      let ip = serverNBT["ip"]!
      let name = serverNBT["name"]!
      
      let server: Server?
      if let url = URL.init(string: "minecraft://\(ip)") {
        if let host = url.host {
          if let port = url.port {
            server = Server(name: name, host: host, port: port, eventManager: eventManager)
          } else {
            server = Server(name: name, host: host, port: 25565, eventManager: eventManager)
          }
        } else {
          // TODO: use logger for these print statements
          print("server ip has no host?")
          continue
        }
      } else {
        print("invalid server ip: \(ip)")
        continue
      }
      servers.append(server!)
    }
    return ServerList(withServers: servers)
  }
  
  static func loadUserProfile(minecraftFolder: URL) {
    let launcherProfilesURL = minecraftFolder.appendingPathComponent("launcher_profiles.json")
    let json = JSON.fromURL(launcherProfilesURL)
    let selectedUser = json.getJSON(forKey: "selectedUser")
    let accountUUID = selectedUser.getString(forKey: "account")
    let profileUUID = selectedUser.getString(forKey: "profile")
  }
}
