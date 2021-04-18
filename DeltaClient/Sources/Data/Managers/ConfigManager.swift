//
//  ConfigManager.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 14/12/20.
//

import Foundation
import os

enum ConfigError: LocalizedError {
  case failedToWriteConfig(Error)
}

class ConfigManager: ObservableObject {
  var storageManager: StorageManager
  var configFile: URL
  @Published var config: Config
  
  init(storageManager: StorageManager) throws {
    self.storageManager = storageManager
    self.configFile = self.storageManager.absoluteFromRelative("config.json")
    if self.storageManager.fileExists(at: self.configFile) {
      do {
        let configJSON = try Data(contentsOf: self.configFile)
        let decoder = JSONDecoder()
        self.config = try decoder.decode(Config.self, from: configJSON)
        if getHasLoggedIn() {
          refreshAccessToken(success: {})
        }
        return
      } catch {
        Logger.warning("failed to load existing config: \(error)")
      }
    }
    
    // fall through means that default config must be created
    Logger.log("resetting config file to defaults")
    try? storageManager.removeFile(configFile)
    self.config = Config.createDefault()
    
    writeConfig()
  }
  
  func writeConfig() {
    do {
      let encoder = JSONEncoder()
      encoder.outputFormatting = .prettyPrinted
      let data = try encoder.encode(config)
      try data.write(to: configFile)
    } catch {
      Logger.error("failed to write config: \(error)")
    }
  }
  
  // Get
  
  func getHasLoggedIn() -> Bool {
    return config.hasLoggedIn
  }
  
  func getServerList() -> ServerList {
    return ServerList(config.servers)
  }
  
  func getServers() -> [ServerDescriptor] {
    return config.servers
  }
  
  func getServer(at index: Int) -> ServerDescriptor {
    return config.servers[index]
  }
  
  func getSelectedProfile() -> MojangProfile? {
    if let uuid = config.selectedProfile {
      return config.profiles[uuid]
    }
    return nil
  }
  
  func getSelectedAccount() -> MojangAccount? {
    return config.account
  }
  
  func getClientToken() -> String {
    return config.clientToken
  }
  
  // Set
  
  func setUser(account: MojangAccount, profiles: [MojangProfile], selectedProfile: String) {
    ThreadUtil.runInMain {
      config.account = account
      for profile in profiles {
        config.profiles[profile.id] = profile
      }
      config.selectedProfile = selectedProfile
      config.hasLoggedIn = true
      writeConfig()
    }
  }
  
  func setSelectedProfile(_ uuid: String) {
    ThreadUtil.runInMain {
      config.selectedProfile = uuid
      writeConfig()
    }
  }
  
  func logout() {
    ThreadUtil.runInMain {
      config.account = nil
      config.profiles = [:]
      config.selectedProfile = nil
      config.hasLoggedIn = false
      writeConfig()
    }
  }
  
  func addServer(_ descriptor: ServerDescriptor) {
    ThreadUtil.runInMain {
      config.servers.append(descriptor)
      writeConfig()
    }
  }
  
  func addServer(_ descriptor: ServerDescriptor, at index: Int) {
    ThreadUtil.runInMain {
      config.servers.insert(descriptor, at: index)
      writeConfig()
    }
  }
  
  func removeServer(at index: Int) {
    ThreadUtil.runInMain {
      config.servers.remove(at: index)
      writeConfig()
    }
  }
  
  // Util
  
  func refreshAccessToken(success: @escaping () -> Void) {
    MojangAPI.refresh(accessToken: self.config.account!.accessToken, clientToken: self.config.clientToken, completion: { newAccessToken in
      self.config.account!.accessToken = newAccessToken
      self.writeConfig()
      success()
    }, failure: {
      self.logout()
    })
  }
}
