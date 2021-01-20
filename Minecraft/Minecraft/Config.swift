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
// TODO: clean up the config class
class Config {
  private var logger: Logger
  
  var minecraftFolder: URL
  var eventManager: EventManager
  
  enum ConfigError: Error {
    case invalidServerListNBT
    case invalidLauncherProfilesJSON
  }
  
  init(minecraftFolder: URL, eventManager: EventManager) {
    self.logger = Logger(for: type(of: self))
    self.minecraftFolder = minecraftFolder
    self.eventManager = eventManager
  }
  
  func getServerList(forClient client: Client) throws -> ServerList {
    let serversDatURL = minecraftFolder.appendingPathComponent("servers.dat")
    do {
      let serversNBT = try NBTCompound(fromURL: serversDatURL)
      let serverNBTList: [NBTCompound] = try serversNBT.getList("servers")
      var servers: [Server] = []
      for serverNBT in serverNBTList {
        let ip: String = try serverNBT.get("ip")
        let name: String = try serverNBT.get("name")
        
        let server: Server?
        if let url = URL.init(string: "minecraft://\(ip)") {
          if let host = url.host {
            if let port = url.port {
              server = Server(name: name, host: host, port: port, eventManager: eventManager, client: client)
            } else {
              server = Server(name: name, host: host, port: 25565, eventManager: eventManager, client: client)
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
      return ServerList(withServers: servers)
    } catch {
      throw ConfigError.invalidServerListNBT
    }
  }
  
  func getLauncherProfile() throws -> LauncherProfile {
    let launcherProfilesURL = minecraftFolder.appendingPathComponent("launcher_profiles.json")
    do {
      let json = try JSON.fromURL(launcherProfilesURL)
      let selectedUser = try json.getJSON(forKey: "selectedUser")
      
      let accountUUID = try UUID.fromString(selectedUser.getString(forKey: "account"))!
      let profileUUID = try UUID.fromString(selectedUser.getString(forKey: "profile"))!
      
      let profile = LauncherProfile(accountUUID: accountUUID, profileUUID: profileUUID)
      return profile
    } catch {
      throw ConfigError.invalidLauncherProfilesJSON
    }
  }
}
