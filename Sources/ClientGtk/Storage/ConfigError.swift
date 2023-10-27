import Foundation

public enum ConfigError: LocalizedError {
  /// The account in question is of an invalid type.
  case invalidAccountType
  /// No account is selected.
  case noAccountSelected
  /// The currently selected account is of an invalid type.
  case invalidSelectedAccountType
  /// Failed to refresh the given account.
  case accountRefreshFailed(Error)
  
  public var errorDescription: String? {
    switch self {
      case .invalidAccountType:
        return "The account in question is of an invalid type."
      case .noAccountSelected:
        return "No account is selected."
      case .invalidSelectedAccountType:
        return "The currently selected account is of an invalid type."
      case .accountRefreshFailed(let error):
        return """
        Failed to refresh the given account.
        Reason: \(error.localizedDescription).
        """
    }
  }
}
