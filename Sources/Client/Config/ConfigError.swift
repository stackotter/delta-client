import Foundation

public enum ConfigError: LocalizedError {
  /// The account in question is of an invalid type.
  case invalidAccountType
  /// No account exists with the given id.
  case invalidAccountId
  /// The currently selected account is of an invalid type.
  case invalidSelectedAccountType
  /// Failed to refresh an account.
  case accountRefreshFailed
  /// Not account has been selected.
  case noAccountSelected
  
  public var errorDescription: String? {
    switch self {
      case .invalidAccountType:
        return "The account in question is of an invalid type."
      case .invalidAccountId:
        return "No such account."
      case .invalidSelectedAccountType:
        return "The currently selected account is of an invalid type."
      case .accountRefreshFailed:
        return "Failed to refresh the given account."
      case .noAccountSelected:
        return "No account has been selected."
    }
  }
}
