import Foundation
import ZippyJSON

public enum MojangAPIError: LocalizedError {
  case failedToDeserializeResponse
  case requestFailed(Error?)
}

// TODO: make these async when Xcode 13.2 is released
// TODO: check status code of responses and handle errors in api response when status code is 403

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
  ///   - clientToken: The client's 'unique' token (Delta Client uses Mojang's client token).
  ///   - completion: Completion handler.
  ///   - failure: Failure handler.
  public static func login(
    email: String,
    password: String,
    clientToken: String,
    onCompletion completion: @escaping (_ account: MojangAccount) -> Void,
    onFailure failure: @escaping (MojangAPIError) -> Void)
  {
    let payload = MojangAuthenticationRequest(
      agent: MojangAgent(),
      username: email,
      password: password,
      clientToken: clientToken,
      requestUser: true)
    
    RequestUtil.performJSONRequest(url: authenticationURL, body: payload, method: .post, onCompletion: { _, data in
      guard let response = try? ZippyJSONDecoder().decode(MojangAuthenticationResponse.self, from: data) else {
        failure(MojangAPIError.failedToDeserializeResponse)
        return
      }
      
      let selectedProfile = response.selectedProfile
      let account = MojangAccount(
        id: response.user.id,
        profileId: selectedProfile.id,
        name: response.selectedProfile.name,
        email: email,
        accessToken: response.accessToken)
      
      completion(account)
    }, onFailure: { error in
      failure(.requestFailed(error))
    })
  }
  
  /// Contacts the Mojang auth servers as part of the join game handshake.
  /// - Parameters:
  ///   - accessToken: User's access token.
  ///   - selectedProfile: UUID of the user's selected profile (one account can have multiple profiles).
  ///   - serverHash: The hash received from the server that is being joined.
  ///   - completion: Completion handler.
  ///   - failure: Failure handler.
  public static func join(
    accessToken: String,
    selectedProfile: String,
    serverHash: String,
    onCompletion completion: @escaping () -> Void,
    onFailure failure: @escaping (MojangAPIError) -> Void)
  {
    let payload = MojangJoinRequest(
      accessToken: accessToken,
      selectedProfile: selectedProfile,
      serverId: serverHash
    )
    
    RequestUtil.performJSONRequest(url: joinServerURL, body: payload, method: .post, onCompletion: { _, _ in
      completion()
    }, onFailure: { error in
      failure(.requestFailed(error))
    })
  }
  
  /// Refreshes the access token of a Mojang account.
  /// - Parameters:
  ///   - account: The account to refresh.
  ///   - clientToken: The client's 'unique' token (Delta Client just uses Mojang's).
  ///   - completion: Completion handler.
  ///   - failure: Failure handler.
  public static func refresh(
    _ account: MojangAccount,
    with clientToken: String,
    onCompletion completion: @escaping (_ account: MojangAccount) -> Void,
    onFailure failure: @escaping (MojangAPIError) -> Void)
  {
    let payload = MojangRefreshTokenRequest(
      accessToken: account.accessToken,
      clientToken: clientToken)
    
    RequestUtil.performJSONRequest(url: refreshURL, body: payload, method: .post, onCompletion: { _, data in
      guard let response = try? ZippyJSONDecoder().decode(MojangRefreshTokenResponse.self, from: data) else {
        failure(MojangAPIError.failedToDeserializeResponse)
        return
      }
      
      var refreshedAccount = account
      refreshedAccount.accessToken = response.accessToken
      completion(refreshedAccount)
    }, onFailure: { error in
      failure(.requestFailed(error))
    })
  }
}
