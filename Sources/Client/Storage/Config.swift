import Foundation
import DeltaCore

public struct Config: Codable {
  /// The random token used to identify ourselves to Mojang's API
  public var clientToken: String
  /// The id of the currently selected account.
  public var selectedAccountId: String?
  /// The type of the currently selected account.
  public var selectedAccountType: AccountType?
  /// The dictionary containing all of the user's Mojang accounts.
  public var mojangAccounts: [String: MojangAccount]
  /// The dictionary containing all of the user's offline accounts.
  public var offlineAccounts: [String: OfflineAccount]
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
  
  /// All of the user's accounts.
  public var accounts: [Account] {
    var accounts: [Account] = []
    accounts.append(contentsOf: [MojangAccount](mojangAccounts.values) as [Account])
    accounts.append(contentsOf: [OfflineAccount](offlineAccounts.values) as [Account])
    return accounts
  }
  
  /// The account the user has currently selected.
  public var selectedAccount: Account? {
    if let id = selectedAccountId {
      switch selectedAccountType {
        case .mojang:
          return mojangAccounts[id]
        case .offline:
          return offlineAccounts[id]
        default:
          return nil
      }
    } else {
      return nil
    }
  }
  
  /// Creates the default config.
  public init() {
    clientToken = UUID().uuidString
    mojangAccounts = [:]
    offlineAccounts = [:]
    servers = []
    render = RenderConfiguration()
    unloadedPlugins = []
    keymap = Keymap(bindings: [
      .forward: .code(13),
      .backward: .code(1),
      .left: .code(0),
      .right: .code(2),
      .jump: .code(49),
      .shift: .modifier(.leftShift),
      .sprint: .modifier(.leftControl)
    ])
    mouseSensitivity = 1
  }
  
  /// Returns the type of the given account
  public static func accountType(_ account: Account) -> AccountType? {
    switch account {
      case _ as MojangAccount:
        return .mojang
      case _ as OfflineAccount:
        return .offline
      default:
        return nil
    }
  }
  
  /// Selects the given account. If given account is nil it sets selected account to nil.
  public mutating func selectAccount(_ account: Account?) throws {
    if let account = account {
      if let type = Self.accountType(account) {
        selectedAccountId = account.id
        selectedAccountType = type
      } else {
        selectedAccountId = nil
        selectedAccountType = nil
        throw ConfigError.invalidAccountType
      }
    } else {
      selectedAccountId = nil
      selectedAccountType = nil
    }
  }
  
  /// Removes all accounts and replaces them with the given accounts.
  public mutating func updateAccounts(_ accounts: [Account]) {
    mojangAccounts = [:]
    offlineAccounts = [:]
    
    accounts.forEach { account in
      switch account {
        case let account as MojangAccount:
          mojangAccounts[account.id] = account
        case let account as OfflineAccount:
          offlineAccounts[account.id] = account
        default:
          break
      }
    }
  }
}
