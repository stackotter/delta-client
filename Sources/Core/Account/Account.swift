import Foundation

/// An account which can be a Microsoft, Mojang or offline account.
public enum Account: Codable, Identifiable {
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
  
  /// Refreshes the account.
  /// - Parameter clientToken: The client token to use when refreshing the account.
  public mutating func refreshIfExpired(withClientToken clientToken: String) async throws {
    switch self {
      case .microsoft(let account):
        if account.accessToken.hasExpired {
          let account = try await MicrosoftAPI.refreshMinecraftAccount(account)
          self = .microsoft(account)
        }
      case .mojang(let account):
        if account.accessToken.hasExpired {
          let account = try await MojangAPI.refresh(account, with: clientToken)
          self = .mojang(account)
        }
      case .offline:
        return
    }
  }
}
