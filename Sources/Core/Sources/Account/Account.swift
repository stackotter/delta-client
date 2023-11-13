import Foundation

/// An account which can be a Microsoft, Mojang or offline account.
public enum Account: Codable, Identifiable, Hashable {
  case microsoft(MicrosoftAccount)
  case mojang(MojangAccount)
  case offline(OfflineAccount)

  /// The account's id.
  public var id: String {
    switch self {
      case .microsoft(let account as OnlineAccount), .mojang(let account as OnlineAccount):
        return account.id
      case .offline(let account):
        return account.id
    }
  }

  /// The account type to display to users.
  public var type: String {
    switch self {
      case .microsoft:
        return "Microsoft"
      case .mojang:
        return "Mojang"
      case .offline:
        return "Offline"
    }
  }

  /// The account's username.
  public var username: String {
    switch self {
      case .microsoft(let account as OnlineAccount), .mojang(let account as OnlineAccount):
        return account.username
      case .offline(let account):
        return account.username
    }
  }

  /// The online version of this account if the account supports online mode.
  public var online: OnlineAccount? {
    switch self {
      case .microsoft(let account as OnlineAccount), .mojang(let account as OnlineAccount):
        return account
      case .offline:
        return nil
    }
  }

  /// The offline version of this account.
  public var offline: OfflineAccount {
    switch self {
      case .microsoft(let account as OnlineAccount), .mojang(let account as OnlineAccount):
        return OfflineAccount(username: account.username)
      case .offline(let account):
        return account
    }
  }

  /// Refreshes the account's access token (if it has one).
  /// - Parameter clientToken: The client token to use when refreshing the account.
  public func refreshed(withClientToken clientToken: String) async throws -> Self {
    switch self {
      case .microsoft(let account):
        let account = try await MicrosoftAPI.refreshMinecraftAccount(account)
        return .microsoft(account)
      case .mojang(let account):
        let account = try await MojangAPI.refresh(account, with: clientToken)
        return .mojang(account)
      case .offline:
        return self
    }
  }

  /// Refreshes the account's access token in place (if it has one).
  /// - Parameter clientToken: The client token to use when refreshing the account.
  public mutating func refresh(withClientToken clientToken: String) async throws {
    self = try await refreshed(withClientToken: clientToken)
  }
}
