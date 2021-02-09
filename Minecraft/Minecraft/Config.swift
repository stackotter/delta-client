//
//  Config.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 14/12/20.
//

import Foundation
import os

// TODO: handle minecraft folder not existing
class Config {
  var minecraftFolder: URL
  var eventManager: EventManager
  
  enum ConfigError: LocalizedError {
    case invalidServerListNBT
    case invalidLauncherProfilesJSON
  }
  
  init(eventManager: EventManager) {
    self.eventManager = eventManager
    
    self.minecraftFolder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("minecraft")
  }
  
  func getServerList() throws -> ServerList {
    let serversDatURL = minecraftFolder.appendingPathComponent("servers.dat")
    do {
      let serversNBT = try NBTCompound(fromURL: serversDatURL)
      let serverNBTList: [NBTCompound] = try serversNBT.getList("servers")
      let serverList = ServerList()
      for serverNBT in serverNBTList {
        let ip: String = try serverNBT.get("ip")
        let name: String = try serverNBT.get("name")
        
        let serverInfo = ServerInfo(name: name, ip: ip)
        
        if serverInfo != nil {
          serverList.addServer(serverInfo!)
        } else {
          Logger.debug("invalid server ip")
        }
      }
      return serverList
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
