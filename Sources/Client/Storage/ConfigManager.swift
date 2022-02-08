import Foundation
import DeltaCore
import ZippyJSON

/// Manages the config stored in a config file.
public final class ConfigManager {
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
        DeltaClientApp.fatal("Failed to encode config: \(error.localizedDescription)")
      }
      return
    }

    // Read the current config from the config file
    do {
      let data = try Data(contentsOf: configFile)
      config = try ZippyJSONDecoder().decode(Config.self, from: data)
    } catch {
      // Existing config is corrupted, overwrite it with defaults
      log.error("Invalid config.json, overwriting with defaults")
      DeltaClientApp.modalError("Invalid config.json, overwriting with defaults")

      config = Config()
      let data: Data
      do {
        data = try JSONEncoder().encode(config)
        FileManager.default.createFile(atPath: configFile.path, contents: data, attributes: nil)
      } catch {
        DeltaClientApp.fatal("Failed to encode config: \(error.localizedDescription)")
      }
    }
  }
  
  /// Refreshes the currently selected account.
  public func refreshSelectedAccount() async throws -> Account {
    guard let account = config.selectedAccount else {
      throw ConfigError.noAccountSelected
    }
    
    switch account {
      case let account as MojangAccount:
        do {
          let account = try await MojangAPI.refresh(account, with: config.clientToken)
          self.config.mojangAccounts[account.id] = account
          self.setConfig(to: self.config)
          return account
        } catch {
          throw ConfigError.accountRefreshFailed(error)
        }
      case let account as OfflineAccount:
        return account
      default:
        throw ConfigError.invalidSelectedAccountType
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

  /// Commits the current config to this manager's config file.
  private func commitConfig() throws {
    let data = try JSONEncoder().encode(config)
    try data.write(to: configFile)
  }
}
