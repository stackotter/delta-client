import Foundation

public enum ConfigError: LocalizedError {
  /// The account in question is of an invalid type.
  case invalidAccountType
  /// No account is selected.
  case noAccountSelected
  /// The currently selected account it of an invalid type.
  case invalidSelectedAccountType
  /// Failed to refresh the given account.
  case accountRefreshFailed(Error)
}
