import Foundation
import DeltaCore

/// Manages the config stored in a config file.
public final class ConfigManager {
  /// The manager for the default config file.
  public static var `default` = ConfigManager(for: StorageManager.default.absoluteFromRelative("config.json"))

  /// The current config (thread-safe).
  public private(set) var config: Config {
    get {
      lock.acquireReadLock()
      defer { lock.unlock() }
      return _config
    }
    set(newValue) {
      lock.acquireWriteLock()
      defer { lock.unlock() }
      _config = newValue
    }
  }

  /// The implementation of ClientConfiguration that allows DeltaCore to access required config values.
  let coreConfiguration: CoreConfiguration
  
  /// The non-threadsafe storage for ``config``.
  private var _config: Config
  /// The file to store config in.
  private let configFile: URL

  /// A queue to ensure that writing to the config file always happens serially.
  private let queue = DispatchQueue(label: "dev.stackotter.delta-client.ConfigManager")
  /// The lock used to synchronise access to ``ConfigManager/_config``.
  private let lock = ReadWriteLock()

  /// Creates a manager for the specified config file. Creates default config if required.
  private init(for configFile: URL) {
    self.configFile = configFile

    // Create default config if no config file exists
    guard StorageManager.fileExists(at: configFile) else {
      _config = Config()
      coreConfiguration = CoreConfiguration(_config)
      let data: Data
      do {
        data = try JSONEncoder().encode(_config)
        FileManager.default.createFile(atPath: configFile.path, contents: data, attributes: nil)
      } catch {
        // TODO: Proper error handling for ConfigManager
        // DeltaClientApp.fatal("Failed to encode config: \(error)")
      }
      return
    }

    // Read the current config from the config file
    do {
      let data = try Data(contentsOf: configFile)
      _config = try CustomJSONDecoder().decode(Config.self, from: data)
    } catch {
      // Existing config is corrupted, overwrite it with defaults
      log.error("Invalid config.json, overwriting with defaults")

      _config = Config()
      let data: Data
      do {
        data = try JSONEncoder().encode(_config)
        FileManager.default.createFile(atPath: configFile.path, contents: data, attributes: nil)
      } catch {
        // DeltaClientApp.fatal("Failed to encode config: \(error)")
      }
    }
    coreConfiguration = CoreConfiguration(_config)
  }
  
  /// Commits the given account to the config file.
  /// - Parameters:
  ///   - account: The account to add.
  ///   - shouldSelect: Whether to select the account or not.
  public func addAccount(_ account: Account, shouldSelect: Bool = false) {
    config.accounts[account.id] = account
    
    if shouldSelect {
      config.selectedAccountId = account.id
    }
    
    try? commitConfig()
  }
  
  /// Selects the given account.
  /// - Parameter id: The id of the account as received from the authentication servers (or generated from the username if offline).
  public func selectAccount(_ id: String?) {
    config.selectedAccountId = id
    try? commitConfig()
  }
  
  /// Commits the given array of user accounts to the config file replacing any existing accounts.
  /// - Parameters:
  ///   - accounts: The user's accounts.
  ///   - selected: Decides which account will be selected.
  public func setAccounts(_ accounts: [Account], selected: String?) {
    config.accounts = [:]
    for account in accounts {
      config.accounts[account.id] = account
    }
    
    config.selectedAccountId = selected
    
    try? commitConfig()
  }
  
  /// Refreshes the currently selected account and returns it.
  /// - Returns: The currently selected account after refreshing it.
  public func getRefreshedAccount() async throws -> Account {
    guard let account = config.selectedAccount else {
      throw ConfigError.noAccountSelected
    }
    
    do {
      try await config.accounts[account.id]?.refreshIfExpired(withClientToken: config.clientToken)
    } catch {
      throw ConfigError.accountRefreshFailed(error)
    }
    
    try commitConfig()
    return account
  }

  /// Updates the config and writes it to the config file.
  /// - Parameter config: The config to write.
  /// - Parameter saveToFile: Whether to write to the file or just update internal references.
  public func setConfig(to config: Config, saveToFile: Bool = true) {
    self.config = config
    
    do {
      try commitConfig(saveToFile: saveToFile)
    } catch {
      log.error("Failed to write config to file: \(error)")
    }
  }
  
  /// Resets the configuration to defaults.
  public func resetConfig() throws {
    log.info("Resetting config.json")
    config = Config()
    try commitConfig()
  }

  /// Commits the current config to this manager's config file.
  /// - Parameter saveToFile: Whether to write to the file or just update internal references.
  private func commitConfig(saveToFile: Bool = true) throws {
    coreConfiguration.config = config

    if saveToFile {
      try queue.sync {
        let data = try JSONEncoder().encode(self.config)
        try data.write(to: self.configFile)
      }
    }
  }
}

/// Enables DeltaCore to access required configuration values.
/// This is passed to the Client constructor.
class CoreConfiguration: ClientConfiguration {
  var config: Config
  
  init(_ config: Config) {
    self.config = config
  }

  public var render: RenderConfiguration {
    get { return config.render }
  }

  public var keymap: Keymap {
    get { return config.keymap }
  }

  public var toggleSprint: Bool {
    get { return config.toggleSprint }
  }

  public var toggleSneak: Bool {
    get { return config.toggleSneak }
  }
}
