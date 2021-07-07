//
//  ConfigManager.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 2/7/21.
//

import Foundation

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
      } catch {
        DeltaClientApp.fatal("Failed to encode config: \(error)")
      }
      FileManager.default.createFile(atPath: configFile.path, contents: data, attributes: nil)
      return
    }
    
    // Read the current config from the config file
    do {
      let data = try Data(contentsOf: configFile)
      config = try JSONDecoder().decode(Config.self, from: data)
    } catch {
      DeltaClientApp.fatal("Failed to read config file: \(error)")
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
