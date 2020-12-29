//
//  Config.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 14/12/20.
//

import Foundation
import os

// NOTE: could possibly be struct instead of class
// TODO_LATER: Get this working under the sandbox
// TODO_LATER: Handle minecraft folder not existing
class Config {
  private var logger: Logger
  
  var minecraftFolder: URL
  var eventManager: EventManager
  
  var serverList: ServerList?
  var launcherProfile: LauncherProfile?
  
  init(minecraftFolder: URL, eventManager: EventManager) {
    self.logger = Logger(for: type(of: self))
    self.minecraftFolder = minecraftFolder
    self.eventManager = eventManager
    
    loadServerList(minecraftFolder: minecraftFolder, eventManager: eventManager, logger: logger)
    loadLauncherProfile(minecraftFolder: minecraftFolder)
  }
  
  func loadServerList(minecraftFolder: URL, eventManager: EventManager, logger: Logger) {
    let serversDatURL = minecraftFolder.appendingPathComponent("servers.dat")
    let serversNBT = NBTCompound(fromURL: serversDatURL)
    let serverNBTList: [NBTCompound] = serversNBT.getList("servers")
    var servers: [Server] = []
    for serverNBT in serverNBTList {
      let ip: String = serverNBT.get("ip")
      let name: String = serverNBT.get("name")
      
      let server: Server?
      if let url = URL.init(string: "minecraft://\(ip)") {
        if let host = url.host {
          if let port = url.port {
            server = Server(name: name, host: host, port: port, eventManager: eventManager)
          } else {
            server = Server(name: name, host: host, port: 25565, eventManager: eventManager)
          }
        } else {
          logger.debug("server ip has no host?")
          continue
        }
      } else {
        logger.debug("invalid server ip: \(ip)")
        continue
      }
      servers.append(server!)
    }
    self.serverList = ServerList(withServers: servers)
  }
  
  func loadLauncherProfile(minecraftFolder: URL) {
    let launcherProfilesURL = minecraftFolder.appendingPathComponent("launcher_profiles.json")
    let json = JSON.fromURL(launcherProfilesURL)
    let selectedUser = json.getJSON(forKey: "selectedUser")
    
    let accountUUID = UUID.fromString(selectedUser.getString(forKey: "account"))
    let profileUUID = UUID.fromString(selectedUser.getString(forKey: "profile"))
    
    let profile = LauncherProfile(accountUUID: accountUUID!, profileUUID: profileUUID!)
    self.launcherProfile = profile
  }
}
