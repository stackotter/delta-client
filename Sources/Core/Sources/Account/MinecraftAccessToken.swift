import Foundation
import CoreFoundation

/// An access token attached to an online account. Used for connecting to online-mode servers.
public struct MinecraftAccessToken: Codable {
  /// The access token.
  public var token: String
  /// The time that the token will expire at in system absolute time. If `nil`, the token won't expire.
  public var expiry: Int?

  /// Whether the access token has expired of not. The access token is valid for 10 more seconds after this changes to `true`.
  public var hasExpired: Bool {
    guard let expiry = expiry else {
      return false
    }

    return Int(CFAbsoluteTimeGetCurrent()) > expiry - 10
  }

  /// Creates a new access token with the given properties.
  /// - Parameters:
  ///   - token: The access token.
  ///   - expiry: The time that the access token will expire at in system absolute time.
  public init(token: String, expiry: Int?) {
    self.token = token
    self.expiry = expiry
  }

  /// Creates a new access token with the given properties.
  /// - Parameters:
  ///   - token: The access token.
  ///   - secondsToLive: The number of seconds that the access token is valid for.
  public init(token: String, expiresIn secondsToLive: Int) {
    self.token = token
    self.expiry = Int(CFAbsoluteTimeGetCurrent()) + secondsToLive
  }
}
