import Foundation
import DeltaCore
import OrderedCollections

/// The client's configuration. Usually stored in a JSON file.
struct Config: Codable, ClientConfiguration {
  /// The random token used to identify ourselves to Mojang's API
  var clientToken = UUID().uuidString
  /// The id of the currently selected account.
  var selectedAccountId: String?
  /// The dictionary containing all of the user's accounts.
  var accounts: [String: Account] = [:]
  /// The user's server list.
  var servers: [ServerDescriptor] = []
  /// Rendering related configuration.
  var render = RenderConfiguration()
  /// Plugins that the user has explicitly unloaded.
  var unloadedPlugins: [String] = []
  /// The user's keymap.
  var keymap = Keymap.default
  /// Whether to use the sprint key as a toggle.
  var toggleSprint = false
  /// Whether to use the sneak key as a toggle.
  var toggleSneak = false
  /// The in game mouse sensitivity
  var mouseSensitivity: Float = 1

  /// The user's accounts, ordered by username.
  var orderedAccounts: [Account] {
    accounts.values.sorted { $0.username <= $1.username }
  }

  /// The account the user has currently selected.
  var selectedAccount: Account? {
    if let id = selectedAccountId {
      return accounts[id]
    } else {
      return nil
    }
  }

  /// Creates the default config.
  init() {}

  /// Loads a configuration from a JSON configuration file.
  static func load(from file: URL) throws -> Config {
    let data = try Data(contentsOf: file)
    return try JSONDecoder().decode(Self.self, from: data)
  }

  /// Saves the configuration to a JSON file.
  func save(to file: URL) throws {
    let data = try JSONEncoder().encode(self)
    try data.write(to: file)
  }

  /// Adds an account to the configuration. If an account with the same id already
  /// exists, it gets replaced.
  mutating func addAccount(_ account: Account) {
    accounts[account.id] = account
  }

  /// Sets the selected account id. If the `id` is `nil`, then no account is selected.
  mutating func selectAccount(withId id: String?) {
    selectedAccountId = id
  }

  /// Adds a collection of accounts to the configuration. Any existing accounts with
  /// overlapping ids are replaced.
  mutating func addAccounts(_ accounts: [Account]) {
    for account in accounts {
      addAccount(account)
    }
  }
}
