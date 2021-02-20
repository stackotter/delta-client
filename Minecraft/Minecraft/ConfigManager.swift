//
//  Config.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 14/12/20.
//

import Foundation
import os

class ConfigManager {
  var minecraftFolder: URL
  var eventManager: EventManager
  
  enum ConfigError: LocalizedError {
    case invalidServerListNBT
    case invalidLauncherProfilesJSON
  }
  
  init(eventManager: EventManager) {
    self.eventManager = eventManager
    // TODO_LATER: handle minecraft folder not existing
    self.minecraftFolder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("minecraft")
  }
  
  func getCurrentConfig() -> Config {
    let serverList = getServerList()
    let launcherProfile = getLauncherProfile()
    let locale = getLocale()
    let config = Config(minecraftFolder: minecraftFolder, serverList: serverList, launcherProfile: launcherProfile, locale: locale)
    return config
  }
  
  func getLocale() -> MinecraftLocale {
    return MinecraftLocale.get("en_us") ?? MinecraftLocale(translations: [:])
  }
  
  func getServerList() -> ServerList {
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
      Logger.warning("failed to load server list from servers.dat")
      return ServerList()
    }
  }
  
  func getLauncherProfile() -> LauncherProfile? {
    let launcherProfilesURL = minecraftFolder.appendingPathComponent("launcher_profiles.json")
    do {
      let json = try JSON.fromURL(launcherProfilesURL)
      let selectedUser = json.getJSON(forKey: "selectedUser")!
      
      let accountUUID = UUID.fromString(selectedUser.getString(forKey: "account")!)!
      let profileUUID = UUID.fromString(selectedUser.getString(forKey: "profile")!)!
      
      let profile = LauncherProfile(accountUUID: accountUUID, profileUUID: profileUUID)
      return profile
    } catch {
      Logger.warning("failed to load launcher profile from launcher_profiles.json")
      return nil
    }
  }
}
