//
//  ConfigManager.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 14/12/20.
//

import Foundation


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
          refreshCurrentAccount(success: {})
        }
        return
      } catch {
        Logger.warn("failed to load existing config: \(error)")
      }
    }
    
    // TODO: don't rely on fall-through (a bit hard to read)
    Logger.info("resetting config file to defaults")
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
  
  func getHasLoggedIn() -> Bool {
    return config.hasLoggedIn
  }
  
  func getConfig() -> Config {
    return config
  }
  
  func selectAccount(uuid: String, type: AccountType) {
    ThreadUtil.runInMain {
      config.selectedAccount = uuid
      config.selectedAccountType = type.rawValue
      config.hasLoggedIn = true
      writeConfig()
    }
  }
  
  func setMojangAccount(withUUID uuid: String, to account: MojangAccount) {
    ThreadUtil.runInMain {
      config.mojangAccounts[uuid] = account
      writeConfig()
    }
  }
  
  func setOfflineAccount(withUUID uuid: String, to account: OfflineAccount) {
    ThreadUtil.runInMain {
      config.offlineAccounts[uuid] = account
      writeConfig()
    }
  }
  
  func addMojangAccount(_ account: MojangAccount) {
    ThreadUtil.runInMain {
      config.mojangAccounts[account.id] = account
      writeConfig()
    }
  }
  
  func addOfflineAccount(_ account: OfflineAccount) {
    ThreadUtil.runInMain {
      config.offlineAccounts[account.id] = account
      writeConfig()
    }
  }
  
  func getSelectedAccountType() -> AccountType? {
    guard let typeString = config.selectedAccountType else {
      return nil
    }
    
    if let type = AccountType(rawValue: typeString) {
      return type
    }
    
    Logger.warn("invalid account type, logging out")
    logout()
    return nil
  }
  
  func getSelectedAccount() -> Account? {
    guard
      let uuid = config.selectedAccount,
      let accountType = getSelectedAccountType()
    else {
      return nil
    }
    
    switch accountType {
      case .mojang:
        if let account = config.mojangAccounts[uuid] {
          return account
        }
      case .offline:
        if let account = config.offlineAccounts[uuid] {
          return account
        }
    }
    
    Logger.warn("selected account doesn't exist, logging out")
    logout()
    return nil
  }
  
  func getAccounts() -> [AccountIdentifier: Account] {
    var accounts: [AccountIdentifier: Account] = [:]
    for (uuid, account) in config.mojangAccounts as [String: Account] {
      accounts[AccountIdentifier(
        uuid: uuid,
        type: .mojang
      )] = account
    }
    for (uuid, account) in config.offlineAccounts as [String: Account] {
      accounts[AccountIdentifier(
        uuid: uuid,
        type: .offline
      )] = account
    }
    return accounts
  }
  
  func logout() {
    ThreadUtil.runInMain {
      config.selectedAccount = nil
      config.selectedAccountType = nil
      config.hasLoggedIn = false
      writeConfig()
    }
  }
  
  func logoutAll() {
    ThreadUtil.runInMain {
      logout()
      config.mojangAccounts = [:]
      config.offlineAccounts = [:]
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
  
  func getServer(at index: Int) -> ServerDescriptor {
    return config.servers[index]
  }
  
  func getServers() -> [ServerDescriptor] {
    return config.servers
  }
  
  func getServerList() -> ServerList {
    return ServerList(config.servers)
  }
  
  func getClientToken() -> String {
    return config.clientToken
  }
  
  func refreshCurrentAccount(success: @escaping () -> Void) {
    if let account = getSelectedAccount() {
      if var mojangAccount = account as? MojangAccount {
        MojangAPI.refresh(
          accessToken: mojangAccount.accessToken,
          clientToken: config.clientToken,
          onCompletion: { newAccessToken in
            mojangAccount.accessToken = newAccessToken
            self.setMojangAccount(withUUID: mojangAccount.id, to: mojangAccount)
            success()
          },
          onFailure: { error in
            Logger.warn("logging out because access token refresh failed: \(error)")
            self.logout()
          })
      }
    }
  }
}
