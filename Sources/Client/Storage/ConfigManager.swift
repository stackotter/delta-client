//
import Foundation
import DeltaCore

// TODO: check which managers actually need to be classes

/// Manages the config stored in a config file.
public class ConfigManager {
  /// The manager for the default config file.
  public static var `default` = ConfigManager(
    for: StorageManager.default.absoluteFromRelative("config.json"))

  /// The current config.
  public private(set) var config: Config
  /// The file to store config in.
  private let configFile: URL

  private let queue = DispatchQueue(label: "dev.stackotter.delta-client.ConfigManager")

  /// Creates a manager for the specified config file. Creates default config if required.
  private init(for configFile: URL) {
    self.configFile = configFile

    // Create default config if no config file exists
    guard StorageManager.default.fileExists(at: configFile) else {
      config = Config()
      let data: Data
      do {
        data = try JSONEncoder().encode(config)
        FileManager.default.createFile(atPath: configFile.path, contents: data, attributes: nil)
      } catch {
        DeltaClientApp.fatal("Failed to encode config: \(error)")
      }
      return
    }

    // Read the current config from the config file
    do {
      let data = try Data(contentsOf: configFile)
      config = try JSONDecoder().decode(Config.self, from: data)
    } catch {
      // Existing config is corrupted, overwrite it with defaults
      log.error("Invalid config.json, overwriting with defaults")
      DeltaClientApp.modalError("Invalid config.json, overwriting with defaults")

      config = Config()
      do {
        try resetConfig()
      } catch {
        DeltaClientApp.fatal("Failed to encode config: \(error)")
      }
    }
  }
  
  /// Refreshes the currently selected account.
  public func refreshSelectedAccount(onCompletion completion: @escaping (Account) -> Void, onFailure failure: @escaping (ConfigError) -> Void) {
    if let account = config.selectedAccount {
      switch account {
        case let account as MojangAccount:
          MojangAPI.refresh(account, with: config.clientToken, onCompletion: { account in
            self.config.mojangAccounts[account.id] = account
            self.setConfig(to: self.config)
            completion(account)
          }, onFailure: { error in
            failure(ConfigError.accountRefreshFailed(error))
          })
        case let account as OfflineAccount:
          completion(account)
        default:
          failure(ConfigError.invalidSelectedAccountType)
      }
    } else {
      failure(ConfigError.noAccountSelected)
    }
  }

  /// Updates the config and writes it to the config file.
  public func setConfig(to config: Config) {
    self.config = config

    queue.async {
      do {
        try self.commitConfig()
      } catch {
        log.error("Failed to write config to file: \(error)")
      }
    }
  }
  
  /// Resets the current config to the default one
  public func resetConfig() throws {
    log.info("Resetting config.json")
    config = Config()
    let data = try JSONEncoder().encode(config)
    FileManager.default.createFile(atPath: configFile.path, contents: data, attributes: nil)
  }

  /// Commits the current config to this manager's config file.
  private func commitConfig() throws {
    let data = try JSONEncoder().encode(config)
    try data.write(to: configFile)
  }
}
