import Foundation

/// An access token used for refreshing Minecraft access tokens attached to Microsoft accounts.
public struct MicrosoftAccessToken: Codable {
  /// The access token.
  public var token: String
  /// The time that the token will expire at in system absolute time.
  public var expiry: Int
  /// The token used to acquire a new access token when it expires.
  public var refreshToken: String
  
  /// Whether the access token has expired or not. Includes a leeway of 10 seconds.
  public var hasExpired: Bool {
    return Int(CFAbsoluteTimeGetCurrent()) > expiry - 10
  }
  
  /// Creates a new access token with the given properties.
  /// - Parameters:
  ///   - token: The access token.
  ///   - expiry: The time that the access token will expire at in system absolute time.
  ///   - refreshToken: The refresh token.
  public init(token: String, expiry: Int, refreshToken: String) {
    self.token = token
    self.expiry = expiry
    self.refreshToken = refreshToken
  }
  
  /// Creates a new access token with the given properties.
  /// - Parameters:
  ///   - token: The access token.
  ///   - secondsToLive: The number of seconds until the access token expires.
  ///   - refreshToken: The refresh token.
  public init(token: String, expiresIn secondsToLive: Int, refreshToken: String) {
    self.token = token
    self.expiry = Int(CFAbsoluteTimeGetCurrent()) + secondsToLive
    self.refreshToken = refreshToken
  }
}
