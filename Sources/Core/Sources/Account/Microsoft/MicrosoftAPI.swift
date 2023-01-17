import Foundation

public enum MicrosoftAPIError: LocalizedError {
  case noUserHashInResponse
  case failedToSerializeRequest
  case failedToDeserializeResponse(Error, String)
  case xstsAuthenticationFailed(XSTSAuthenticationError)
  case expiredAccessToken

  case failedToGetOAuthCodeFromURL(URL)
  case failedToGetMicrosoftAccessToken(Error)
  case failedToGetXboxLiveToken(Error)
  case failedToGetXSTSToken(Error)
  case failedToGetMinecraftAccessToken(Error)
  case failedToGetAttachedLicenses(Error)
  case accountDoesntOwnMinecraft
  case failedToGetMinecraftAccount(Error)

  public var errorDescription: String? {
    switch self {
      case .noUserHashInResponse:
        return "No user hash in response."
      case .failedToSerializeRequest:
        return "Failed to serialize request."
      case .failedToDeserializeResponse(let error, let string):
        return """
        Failed to deserialize response.
        Reason: \(error.localizedDescription)
        Data: \(string)
        """
      case .xstsAuthenticationFailed(let xstsAuthenticationError):
        return """
        XSTS authentication failed.
        Code: \(xstsAuthenticationError.code)
        Identity: \(xstsAuthenticationError.identity)
        Message: \(xstsAuthenticationError.message)
        Redirect: \(xstsAuthenticationError.redirect)
        """
      case .expiredAccessToken:
        return "Expired access token."
      case .failedToGetOAuthCodeFromURL(let url):
        return """
        Failed to get OAuth code from URL.
        URL: \(url.absoluteString)
        """
      case .failedToGetMicrosoftAccessToken(let error):
        return """
        Failed to get microsoft access token.
        Reason: \(error.localizedDescription)
        """
      case .failedToGetXboxLiveToken(let error):
        return """
        Failed to get Xbox Live token.
        Reason: \(error.localizedDescription)
        """
      case .failedToGetXSTSToken(let error):
        return """
        Failed to get XSTS token.
        Reason: \(error.localizedDescription)
        """
      case .failedToGetMinecraftAccessToken(let error):
        return """
        Failed to get Minecraft access token.
        Reason: \(error.localizedDescription)
        """
      case .failedToGetAttachedLicenses(let error):
        return """
        Failed to get attached licenses.
        Reason: \(error.localizedDescription)
        """
      case .accountDoesntOwnMinecraft:
        return "Account doesnt own Minecraft."
      case .failedToGetMinecraftAccount(let error):
        return """
        Failed to get Minecraft account.
        Reason: \(error.localizedDescription)
        """
    }
  }
}

/// A utility for interacting with the Microsoft authentication API.
///
/// ## Overview
///
/// First, device authorization is obtained via ``authorizeDevice()``. The user must then visit the
/// verification url provided in the ``MicrosoftDeviceAuthorizationResponse`` and enter the
/// `userCode` also provided in the response.
///
/// Once the user has completed the interactive part of logging in, ``getMicrosoftAccessToken(_:)``
/// is used to convert the device code into a Microsoft access token.
///
/// ``getMinecraftAccount(_:)`` can then be called with the access token, resulting in an
/// authenticated Microsoft-based Minecraft account.
public enum MicrosoftAPI {
  // swiftlint:disable force_unwrapping
  /// The client id used for Microsoft authentication.
  public static let clientId = "e5c1b05f-4e94-4747-90bf-3e9d40f830f1"

  private static let xstsSandboxId = "RETAIL"
  private static let xstsRelyingParty = "rp://api.minecraftservices.com/"

  private static let authorizationURL = URL(string: "https://login.microsoftonline.com/consumers/oauth2/v2.0/devicecode")!
  private static let authenticationURL = URL(string: "https://login.microsoftonline.com/consumers/oauth2/v2.0/token")!

  private static let xboxLiveAuthenticationURL = URL(string: "https://user.auth.xboxlive.com/user/authenticate")!
  private static let xstsAuthenticationURL = URL(string: "https://xsts.auth.xboxlive.com/xsts/authorize")!
  private static let minecraftXboxAuthenticationURL = URL(string: "https://api.minecraftservices.com/authentication/login_with_xbox")!

  private static let gameOwnershipURL = URL(string: "https://api.minecraftservices.com/entitlements/mcstore")!
  private static let minecraftProfileURL = URL(string: "https://api.minecraftservices.com/minecraft/profile")!
  // swiftlint:enable force_unwrapping

  // MARK: Public methods

  /// Authorizes this device (metaphorically). This is the first step in authenticating a user.
  /// - Returns: A device authorization response.
  public static func authorizeDevice() async throws -> MicrosoftDeviceAuthorizationResponse {
    let (_, data) = try await RequestUtil.performFormRequest(
      url: authorizationURL,
      body: [
        "client_id": clientId,
        "scope": "XboxLive.signin offline_access"
      ],
      method: .post
    )

    let response: MicrosoftDeviceAuthorizationResponse = try decodeResponse(data)
    // TODO: extract the error type if the response isn't a valid access token response

    return response
  }

  /// Fetches an access token for the user after they have completed the interactive login process.
  /// - Parameter deviceCode: The device code used during authentication.
  /// - Returns: An authenticated Microsoft access token.
  public static func getMicrosoftAccessToken(_ deviceCode: String) async throws -> MicrosoftAccessToken {
    let (_, data) = try await RequestUtil.performFormRequest(
      url: authenticationURL,
      body: [
        "tenant": "concumers",
        "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
        "client_id": clientId,
        "device_code": deviceCode
      ],
      method: .post
    )

    let response: MicrosoftAccessTokenResponse = try decodeResponse(data)
    // TODO: extract the error type if the response isn't a valid access token response

    let accessToken = MicrosoftAccessToken(
      token: response.accessToken,
      expiresIn: response.expiresIn,
      refreshToken: response.refreshToken
    )

    return accessToken
  }

  /// Gets the user's Minecraft account.
  /// - Parameters:
  ///   - minecraftAccessToken: The user's Minecraft access token.
  ///   - microsoftAccessToken: The user's Microsoft access token.
  /// - Returns: The user's Minecraft account.
  public static func getMinecraftAccount(
    _ minecraftAccessToken: MinecraftAccessToken,
    _ microsoftAccessToken: MicrosoftAccessToken
  ) async throws -> MicrosoftAccount {
    var request = Request(minecraftProfileURL)
    request.method = .get
    request.headers["Authorization"] = "Bearer \(minecraftAccessToken.token)"

    let (_, data) = try await RequestUtil.performRequest(request)

    let response: MicrosoftMinecraftProfileResponse = try decodeResponse(data)

    return MicrosoftAccount(
      id: response.id,
      username: response.name,
      minecraftAccessToken: minecraftAccessToken,
      microsoftAccessToken: microsoftAccessToken
    )
  }

  /// Gets the user's Microsoft-based Minecraft account from their Microsoft access token.
  /// - Parameter microsoftAccessToken: The user's Microsoft access token with suitable scope
  ///   `XboxLive.signin` and `offline_access`.
  /// - Returns: An authenticated and authorized Microsoft-based Minecraft account.
  public static func getMinecraftAccount(_ microsoftAccessToken: MicrosoftAccessToken) async throws -> MicrosoftAccount {
    // Get Xbox live token
    let xboxLiveToken: XboxLiveToken
    do {
      xboxLiveToken = try await MicrosoftAPI.getXBoxLiveToken(microsoftAccessToken)
    } catch {
      throw MicrosoftAPIError.failedToGetXboxLiveToken(error)
    }

    // Get XSTS token
    let xstsToken: String
    do {
      xstsToken = try await MicrosoftAPI.getXSTSToken(xboxLiveToken)
    } catch {
      throw MicrosoftAPIError.failedToGetXSTSToken(error)
    }

    // Get Minecraft access token
    let minecraftAccessToken: MinecraftAccessToken
    do {
      minecraftAccessToken = try await MicrosoftAPI.getMinecraftAccessToken(xstsToken, xboxLiveToken)
    } catch {
      throw MicrosoftAPIError.failedToGetMinecraftAccessToken(error)
    }

    // Get a list of the user's licenses
    let licenses: [GameOwnershipResponse.License]
    do {
      licenses = try await MicrosoftAPI.getAttachedLicenses(minecraftAccessToken)
    } catch {
      throw MicrosoftAPIError.failedToGetAttachedLicenses(error)
    }

    if licenses.isEmpty {
      throw MicrosoftAPIError.accountDoesntOwnMinecraft
    }

    // Get the user's account
    let account: MicrosoftAccount
    do {
      account = try await MicrosoftAPI.getMinecraftAccount(minecraftAccessToken, microsoftAccessToken)
    } catch {
      throw MicrosoftAPIError.failedToGetMinecraftAccount(error)
    }

    return account
  }

  /// Refreshes a Minecraft account which is attached to a Microsoft account.
  /// - Parameter account: The account to refresh.
  /// - Returns: The refreshed account.
  public static func refreshMinecraftAccount(_ account: MicrosoftAccount) async throws -> MicrosoftAccount {
    log.debug("Start refresh microsoft account")
    var account = account
    if account.microsoftAccessToken.hasExpired {
      account.microsoftAccessToken = try await MicrosoftAPI.refreshMicrosoftAccessToken(account.microsoftAccessToken)
    }

    account = try await MicrosoftAPI.getMinecraftAccount(account.microsoftAccessToken)
    log.debug("Finish refresh microsoft account")
    return account
  }

  // MARK: Private methods

  /// Acquires a new access token for the user's account using an existing refresh token.
  /// - Parameter token: The access token to refresh.
  /// - Returns: The refreshed access token.
  private static func refreshMicrosoftAccessToken(_ token: MicrosoftAccessToken) async throws -> MicrosoftAccessToken {
    let formData = [
      "client_id": clientId,
      "refresh_token": token.refreshToken,
      "grant_type": "refresh_token",
      "scope": "service::user.auth.xboxlive.com::MBI_SSL"
    ]

    let (_, data) = try await RequestUtil.performFormRequest(
      url: authenticationURL,
      body: formData,
      method: .post
    )

    let response: MicrosoftAccessTokenResponse = try decodeResponse(data)

    let accessToken = MicrosoftAccessToken(
      token: response.accessToken,
      expiresIn: response.expiresIn,
      refreshToken: response.refreshToken
    )

    return accessToken
  }

  /// Gets the user's Xbox Live token from their Microsoft access token.
  /// - Parameters:
  ///   - accessToken: The user's Microsoft access token.
  /// - Returns: The user's Xbox Live token.
  private static func getXBoxLiveToken(_ accessToken: MicrosoftAccessToken) async throws -> XboxLiveToken {
    guard !accessToken.hasExpired else {
      throw MicrosoftAPIError.expiredAccessToken
    }

    let payload = XboxLiveAuthenticationRequest(
      properties: XboxLiveAuthenticationRequest.Properties(
        authMethod: "RPS",
        siteName: "user.auth.xboxlive.com",
        accessToken: "d=\(accessToken.token)"
      ),
      relyingParty: "http://auth.xboxlive.com",
      tokenType: "JWT"
    )

    let (_, data) = try await RequestUtil.performJSONRequest(
      url: xboxLiveAuthenticationURL,
      body: payload,
      method: .post
    )

    let response: XboxLiveAuthenticationResponse = try decodeResponse(data)

    guard let userHash = response.displayClaims.xui.first?.userHash else {
      throw MicrosoftAPIError.noUserHashInResponse
    }

    return XboxLiveToken(token: response.token, userHash: userHash)
  }

  /// Gets the user's XSTS token from their Xbox Live token.
  /// - Parameters:
  ///   - xboxLiveToken: The user's Xbox Live token.
  /// - Returns: The user's XSTS token.
  private static func getXSTSToken(_ xboxLiveToken: XboxLiveToken) async throws -> String {
    let payload = XSTSAuthenticationRequest(
      properties: XSTSAuthenticationRequest.Properties(
        sandboxId: xstsSandboxId,
        userTokens: [xboxLiveToken.token]
      ),
      relyingParty: xstsRelyingParty,
      tokenType: "JWT"
    )

    let (_, data) = try await RequestUtil.performJSONRequest(
      url: xstsAuthenticationURL,
      body: payload,
      method: .post
    )

    guard let response: XSTSAuthenticationResponse = try? decodeResponse(data) else {
      let error: XSTSAuthenticationError
      do {
        error = try decodeResponse(data)
      } catch {
        throw MicrosoftAPIError.failedToDeserializeResponse(error, String(decoding: data, as: UTF8.self))
      }

      throw MicrosoftAPIError.xstsAuthenticationFailed(error)
    }

    return response.token
  }

  /// Gets the Minecraft access token from the user's XSTS token.
  /// - Parameters:
  ///   - xstsToken: The user's XSTS token.
  ///   - xboxLiveToken: The user's Xbox Live token.
  /// - Returns: The user's Minecraft access token.
  private static func getMinecraftAccessToken(_ xstsToken: String, _ xboxLiveToken: XboxLiveToken) async throws -> MinecraftAccessToken {
    let payload = MinecraftXboxAuthenticationRequest(
      identityToken: "XBL3.0 x=\(xboxLiveToken.userHash);\(xstsToken)")

    let (_, data) = try await RequestUtil.performJSONRequest(
      url: minecraftXboxAuthenticationURL,
      body: payload,
      method: .post
    )

    let response: MinecraftXboxAuthenticationResponse = try decodeResponse(data)

    let token = MinecraftAccessToken(
      token: response.accessToken,
      expiresIn: response.expiresIn
    )

    return token
  }

  /// Gets the license attached to an account.
  /// - Parameters:
  ///   - accessToken: The user's Minecraft access token.
  /// - Returns: The licenses attached to the user's Microsoft account.
  private static func getAttachedLicenses(_ accessToken: MinecraftAccessToken) async throws -> [GameOwnershipResponse.License] {
    var request = Request(gameOwnershipURL)
    request.method = .get
    request.headers["Authorization"] = "Bearer \(accessToken.token)"

    let (_, data) = try await RequestUtil.performRequest(request)

    let response: GameOwnershipResponse = try decodeResponse(data)

    return response.items
  }

  /// A helper function for decoding JSON responses.
  /// - Parameter data: The JSON data.
  /// - Returns: The decoded response.
  private static func decodeResponse<Response: Decodable>(_ data: Data) throws -> Response {
    do {
      return try CustomJSONDecoder().decode(Response.self, from: data)
    } catch {
      throw MicrosoftAPIError.failedToDeserializeResponse(error, String(decoding: data, as: UTF8.self))
    }
  }
}
