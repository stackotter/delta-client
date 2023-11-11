import Foundation
import DeltaCore

/// Manages the config stored in a config file.
@dynamicMemberLookup
final class ManagedConfig: ObservableObject {
  /// The current config (thread-safe).
  var config: Config {
    willSet {
      objectWillChange.send()
    }
    didSet {
      do {
        // TODO: Reduce the number of writes to disk, perhaps by asynchronously
        //   debouncing. Often multiple config changes will happen in very quick
        //   succession.
        try config.save(to: file)
      } catch {
        saveErrorHandler?(error)
      }
    }
  }

  subscript<T>(dynamicMember member: WritableKeyPath<Config, T>) -> T {
    get {
      config[keyPath: member]
    }
    set {
      config[keyPath: member] = newValue
    }
  }

  /// The file the configuration is stored in.
  let file: URL
  /// A handler for errors which occur when attempting to save the configuration
  /// to disk in the background.
  let saveErrorHandler: ((any Error) -> Void)?

  /// Manages a configuration backed by a given file.
  init(_ config: Config, backedBy file: URL, saveErrorHandler: ((any Error) -> Void)?) {
    self.file = file
    self.config = config
    self.saveErrorHandler = saveErrorHandler
  }

  /// Resets the configuration to defaults.
  func reset() throws {
    config = Config()
  }

  /// Refreshes the specified account if necessary, saves it, and returns it (if
  /// an account exists with the given id). 
  func refreshAccount(withId id: String) async throws -> Account {
    // Takes an id instead of a whole account to make it clear that it's
    // operating in-place on the config (taking an account would make it
    // unclear whether the account must be in the underlying config and
    // whether it gets saved after getting refreshed).
    guard let account = config.accounts[id] else {
      throw ConfigError.invalidAccountId.with("Id", id)
    }

    guard account.online?.accessToken.hasExpired == true else {
      return account
    }
    
    do {
      let refreshedAccount = try await account.refreshed(withClientToken: config.clientToken)
      config.addAccount(refreshedAccount)
      return refreshedAccount
    } catch {
      throw ConfigError.accountRefreshFailed
        .with("Username", account.username)
        .becauseOf(error)
    }
  }

  /// Gets the currently selected account (throws if no account is selected),
  /// and refreshes the account if necessary. May seem like the function is
  /// doing too much, but it's beneficial for usage of this to be concise.
  func selectedAccountRefreshedIfNecessary() async throws -> Account {
    guard let account = config.selectedAccount else {
      throw ConfigError.noAccountSelected
    }

    return try await refreshAccount(withId: account.id)
  }

  // TODO: Maybe we just shouldn't even refresh at app start, we could just refresh at time of
  //   use.
  /// Refreshes all accounts which are close to expiring or have expired.
  /// - Returns: Any errors which occurred during account refreshing.
  func refreshAccounts() async -> [any Error] {
    var errors: [any Error] = []
    for account in config.accounts.values {
      do {
        _ = try await refreshAccount(withId: account.id)
      } catch {
        errors.append(error)
      }
    }
    return errors
  }
}

extension ManagedConfig: ClientConfiguration {
  var render: RenderConfiguration {
    get {
      config.render
    }
    set {
      config.render = newValue
    }
  }

  var keymap: Keymap {
    get {
      config.keymap
    }
    set {
      config.keymap = newValue
    }
  }

  var toggleSprint: Bool {
    get {
      config.toggleSprint
    }
    set {
      config.toggleSprint = newValue
    }
  }

  var toggleSneak: Bool {
    get {
      config.toggleSneak
    }
    set {
      config.toggleSneak = newValue
    }
  }
}
