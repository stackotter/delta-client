//
//  ConfigManager.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 14/12/20.
//

import Foundation
import os

class ConfigManager {
  var storageManager: StorageManager
  var minecraftFolder: URL
  
  enum ConfigError: LocalizedError {
    case invalidServerListNBT
    case invalidLauncherProfilesJSON
    case failedToLoadLauncherProfile
  }
  
  init(storageManager: StorageManager) {
    self.storageManager = storageManager
    self.minecraftFolder = storageManager.getMinecraftFolder()
  }
  
  func getServerList(managers: Managers) -> ServerList {
    let serversDatURL = minecraftFolder.appendingPathComponent("servers.dat")
    do {
      let serversNBT = try NBTCompound(fromURL: serversDatURL)
      let serverNBTList: [NBTCompound] = try serversNBT.getList("servers")
      let serverList = ServerList(managers: managers)
      for serverNBT in serverNBTList {
        let ip: String = try serverNBT.get("ip")
        let name: String = try serverNBT.get("name")
        
        let serverDescriptor = ServerDescriptor(name: name, ip: ip)
        
        if let descriptor = serverDescriptor {
          serverList.addServer(descriptor)
        } else {
          Logger.debug("invalid server ip")
        }
      }
      return serverList
    } catch {
      Logger.warning("failed to load server list from servers.dat")
      return ServerList(managers: managers)
    }
  }
  
  func getLauncherProfile() throws -> LauncherProfile {
    let launcherProfilesURL = minecraftFolder.appendingPathComponent("launcher_profiles.json")
    do {
      let json = try JSON.fromURL(launcherProfilesURL)
      let selectedUser = json.getJSON(forKey: "selectedUser")!
      
      let accountUUID = UUID.fromString(selectedUser.getString(forKey: "account")!)!
      let profileUUID = UUID.fromString(selectedUser.getString(forKey: "profile")!)!
      
      let profile = LauncherProfile(accountUUID: accountUUID, profileUUID: profileUUID)
      return profile
    } catch {
      Logger.error("failed to load launcher profile from launcher_profiles.json")
      throw ConfigError.failedToLoadLauncherProfile
    }
  }
}
