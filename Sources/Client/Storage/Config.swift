import Foundation
import DeltaCore

public struct Config: Codable {
  /// The random token used to identify ourselves to Mojang's API
  public var clientToken: String
  /// The id of the currently selected account.
  public var selectedAccountId: String?
  /// The dictionary containing all of the user's accounts.
  public var accounts: [String: Account]
  /// The user's server list.
  public var servers: [ServerDescriptor]
  /// Rendering related configuration.
  public var render: RenderConfiguration
  /// Plugins that the user has explicitly unloaded.
  public var unloadedPlugins: [String]
  /// The user's keymap.
  public var keymap: Keymap
  /// The in game mouse sensitivity
  public var mouseSensitivity: Float

  /// The account the user has currently selected.
  public var selectedAccount: Account? {
    if let id = selectedAccountId {
      return accounts[id]
    } else {
      return nil
    }
  }

  /// Creates the default config.
  public init() {
    clientToken = UUID().uuidString
    accounts = [:]
    servers = []
    render = RenderConfiguration()
    unloadedPlugins = []
    keymap = Keymap.default
    mouseSensitivity = 1
  }
}
