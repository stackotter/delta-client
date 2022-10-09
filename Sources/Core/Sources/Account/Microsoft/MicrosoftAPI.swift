import Foundation
import ZippyJSON

public enum MicrosoftAPIError: LocalizedError {
  case invalidRedirectURL
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
      case .invalidRedirectURL:
        return "Invalid redirect URL."
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
      case .xstsAuthenticationFailed(let xSTSAuthenticationError):
        return """
        XSTS authentication failed.
        Code: \(xSTSAuthenticationError.code)
        Identity: \(xSTSAuthenticationError.identity)
        Message: \(xSTSAuthenticationError.message)
        Redirect: \(xSTSAuthenticationError.redirect)
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

public enum MicrosoftAPI {
  // swiftlint:disable force_unwrapping
  /// The client id used for talking to the Microsoft API. Delta Client just uses Mojang's client id.
  public static let clientId = "00000000402b5328" // This is mojang's client id
  /// The redirect URL Delta Client uses for Microsoft OAuth.
  public static let redirectURL = URL(string: "ms-xal-\(clientId)://auth")!
  
  private static let xstsSandboxId = "RETAIL"
  private static let xstsRelyingParty = "rp://api.minecraftservices.com/"
  
  private static let authorizationBaseURL = URL(string: "https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize")!
  private static let authenticationURL = URL(string: "https://login.live.com/oauth20_token.srf")!
  
  private static let xboxLiveAuthenticationURL = URL(string: "https://user.auth.xboxlive.com/user/authenticate")!
  private static let xstsAuthenticationURL = URL(string: "https://xsts.auth.xboxlive.com/xsts/authorize")!
  private static let minecraftXboxAuthenticationURL = URL(string: "https://api.minecraftservices.com/authentication/login_with_xbox")!
  
  private static let gameOwnershipURL = URL(string: "https://api.minecraftservices.com/entitlements/mcstore")!
  private static let minecraftProfileURL = URL(string: "https://api.minecraftservices.com/minecraft/profile")!
  // swiftlint:enable force_unwrapping
  
  // MARK: Public methods
  
  /// Gets the OAuth authorization URL.
  /// - Returns: The URL for OAuth authorization.
  public static func getAuthorizationURL() -> URL {
    let url = authorizationBaseURL.appendingQueryItems([
      "client_id": clientId,
      "response_type": "code",
      "scope": "XboxLive.signin offline_access"
    ])
    
    return url
  }
  
  /// Gets the user's Minecraft account.
  /// - Parameter minecraftAccessToken: The user's Minecraft access token.
  /// - Parameter microsoftAccessToken: The user's Microsoft access token.
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
  
  /// Gets the user's Minecraft account using the OAuth code in a redirect URL.
  /// - Parameter oAuthRedirectURL: The URL that the user was redirected to after authorizing Delta Client.
  /// - Returns: The user's Minecraft account.
  public static func getMinecraftAccount(_ oAuthRedirectURL: URL) async throws -> MicrosoftAccount {
    guard let code = MicrosoftAPI.codeFromRedirectURL(oAuthRedirectURL) else {
      throw MicrosoftAPIError.failedToGetOAuthCodeFromURL(oAuthRedirectURL)
    }
    
    // Get Microsoft access token
    let microsoftAccessToken: MicrosoftAccessToken
    do {
      microsoftAccessToken = try await MicrosoftAPI.getMicrosoftAccessToken(authorizationCode: code)
    } catch {
      throw MicrosoftAPIError.failedToGetMicrosoftAccessToken(error)
    }
    
    return try await MicrosoftAPI.getMinecraftAccount(microsoftAccessToken)
  }
  
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
    var account = account
    if account.microsoftAccessToken.hasExpired {
      account.microsoftAccessToken = try await MicrosoftAPI.refreshMicrosoftAccessToken(account.microsoftAccessToken)
    }
    
    return try await MicrosoftAPI.getMinecraftAccount(account.microsoftAccessToken)
  }
  
  // MARK: Private methods
  
  /// Extracts the user's OAuth authorization code from the OAuth redirect URL's query parameters.
  /// - Parameter url: The OAuth redirect URL.
  /// - Returns: The user's OAuth code. `nil` if the URL doesn't contain an OAuth code.
  private static func codeFromRedirectURL(_ url: URL) -> String? {
    guard let components = URLComponents(string: url.absoluteString), let queryItems = components.queryItems else {
      return nil
    }
    
    for item in queryItems where item.name == "code" {
      if let code = item.value {
        return code
      }
    }
    
    return nil
  }
  
  /// Gets the user's Microsoft access token from their OAuth authorization code.
  /// - Parameters:
  ///   - authorizationCode: The user's authorization code.
  private static func getMicrosoftAccessToken(authorizationCode: String) async throws -> MicrosoftAccessToken {
    let formData = [
      "client_id": clientId,
      "code": authorizationCode,
      "grant_type": "authorization_code",
      "scope": "service::user.auth.xboxlive.com::MBI_SSL"
    ]
    
    let (_, data) = try await RequestUtil.performFormRequest(
      url: authenticationURL,
      body: formData,
      method: .post)
    
    let response: MicrosoftAccessTokenResponse = try decodeResponse(data)
    
    let accessToken = MicrosoftAccessToken(
      token: response.accessToken,
      expiresIn: response.expiresIn,
      refreshToken: response.refreshToken)
    
    return accessToken
  }
  
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
      method: .post)
    
    let response: MicrosoftAccessTokenResponse = try decodeResponse(data)
    
    let accessToken = MicrosoftAccessToken(
      token: response.accessToken,
      expiresIn: response.expiresIn,
      refreshToken: response.refreshToken)
    
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
        accessToken: "\(accessToken.token)"),
      relyingParty: "http://auth.xboxlive.com",
      tokenType: "JWT")
    
    let (_, data) = try await RequestUtil.performJSONRequest(
      url: xboxLiveAuthenticationURL,
      body: payload,
      method: .post)
    
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
        userTokens: [xboxLiveToken.token]),
      relyingParty: xstsRelyingParty,
      tokenType: "JWT")
    
    let (_, data) = try await RequestUtil.performJSONRequest(
      url: xstsAuthenticationURL,
      body: payload,
      method: .post)
    
    guard let response: XSTSAuthenticationResponse = try? decodeResponse(data) else {
      let error: XSTSAuthenticationError
      do {
        error = try decodeResponse(data)
      } catch {
        throw MicrosoftAPIError.failedToDeserializeResponse(error, String(data: data, encoding: .utf8) ?? "")
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
      method: .post)
    
    let response: MinecraftXboxAuthenticationResponse = try decodeResponse(data)
    
    let token = MinecraftAccessToken(
      token: response.accessToken,
      expiresIn: response.expiresIn)
    
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
      throw MicrosoftAPIError.failedToDeserializeResponse(error, String(data: data, encoding: .utf8) ?? "")
    }
  }
}
