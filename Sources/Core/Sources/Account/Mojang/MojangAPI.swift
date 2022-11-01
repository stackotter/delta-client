import Foundation

public enum MojangAPIError: LocalizedError {
  case failedToDeserializeResponse(String)
  
  public var errorDescription: String? {
    switch self {
      case .failedToDeserializeResponse(let string):
        return """
        Failed to deserialize response.
        Data: \(string)
        """
    }
  }
}

/// Used to interface with Mojang's authentication API.
public enum MojangAPI {
  // swiftlint:disable force_unwrapping
  private static let authenticationURL = URL(string: "https://authserver.mojang.com/authenticate")!
  private static let joinServerURL = URL(string: "https://sessionserver.mojang.com/session/minecraft/join")!
  private static let refreshURL = URL(string: "https://authserver.mojang.com/refresh")!
  // swiftlint:enable force_unwrapping
  
  /// Log into a Mojang account using an email and password.
  /// - Parameters:
  ///   - email: User's email.
  ///   - password: User's password.
  ///   - clientToken: The client's unique token (different for each user).
  public static func login(
    email: String,
    password: String,
    clientToken: String
  ) async throws -> Account {
    let payload = MojangAuthenticationRequest(
      username: email,
      password: password,
      clientToken: clientToken,
      requestUser: true)
    
    let (_, data) = try await RequestUtil.performJSONRequest(url: authenticationURL, body: payload, method: .post)
    
    guard let response = try? CustomJSONDecoder().decode(MojangAuthenticationResponse.self, from: data) else {
      throw MojangAPIError.failedToDeserializeResponse(String(decoding: data, as: UTF8.self))
    }
    
    let accessToken = MinecraftAccessToken(
      token: response.accessToken,
      expiry: nil)
    
    let selectedProfile = response.selectedProfile
    let account = MojangAccount(
      id: selectedProfile.id,
      username: response.selectedProfile.name,
      accessToken: accessToken)
    
    return Account.mojang(account)
  }
  
  /// Contacts the Mojang auth servers as part of the join game handshake.
  /// - Parameters:
  ///   - accessToken: User's access token.
  ///   - selectedProfile: UUID of the user's selected profile (one account can have multiple profiles).
  ///   - serverHash: The hash received from the server that is being joined.
  public static func join(
    accessToken: String,
    selectedProfile: String,
    serverHash: String
  ) async throws {
    let payload = MojangJoinRequest(
      accessToken: accessToken,
      selectedProfile: selectedProfile,
      serverId: serverHash)
    
    _ = try await RequestUtil.performJSONRequest(url: joinServerURL, body: payload, method: .post)
  }
  
  /// Refreshes the access token of a Mojang account.
  /// - Parameters:
  ///   - account: The account to refresh.
  ///   - clientToken: The client's 'unique' token (Delta Client just uses Mojang's).
  public static func refresh(
    _ account: MojangAccount,
    with clientToken: String
  ) async throws -> MojangAccount {
    let accessToken = String(account.accessToken.token.split(separator: ".")[1])
    let payload = MojangRefreshTokenRequest(
      accessToken: accessToken,
      clientToken: clientToken)
    
    let (_, data) = try await RequestUtil.performJSONRequest(url: refreshURL, body: payload, method: .post)
    
    guard let response = try? CustomJSONDecoder().decode(MojangRefreshTokenResponse.self, from: data) else {
      throw MojangAPIError.failedToDeserializeResponse(String(decoding: data, as: UTF8.self))
    }
    
    var refreshedAccount = account
    refreshedAccount.accessToken = MinecraftAccessToken(token: response.accessToken, expiry: nil)
    
    return refreshedAccount
  }
}
