import Foundation
import ZippyJSON

public enum MicrosoftAPIError: LocalizedError {
  case invalidRedirectURL
  case noUserHashInResponse
  case failedToSerializeRequest
  case failedToDeserializeResponse(String)
  case xstsAuthenticationFailed(XSTSAuthenticationError)
  case requestFailed(Error)
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
  // swiftlint:enable force_unwrapping
  
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
  
  /// Extracts the user's OAuth authorization code from the OAuth redirect URL's query parameters.
  /// - Parameter url: The OAuth redirect URL.
  /// - Returns: The user's OAuth code. `nil` if the URL doesn't contain an OAuth code.
  public static func codeFromRedirectURL(_ url: URL) -> String? {
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
  public static func getMicrosoftAccessToken(authorizationCode: String) async throws -> String {
    let formData = [
      "client_id": clientId,
      "code": authorizationCode,
      "grant_type": "authorization_code",
      "scope": "service::user.auth.xboxlive.com::MBI_SSL"]
    
    let data: Data
    do {
      let (_, response) = try await RequestUtil.performFormRequest(
        url: authenticationURL,
        body: formData,
        method: .post)
      data = response
    } catch {
      throw MicrosoftAPIError.requestFailed(error)
    }
    
    guard let response = try? ZippyJSONDecoder().decode(MicrosoftAccessTokenResponse.self, from: data) else {
      throw MicrosoftAPIError.failedToDeserializeResponse(String(data: data, encoding: .utf8) ?? "")
    }
    
    return response.accessToken
  }
  
  /// Gets the user's Xbox Live token from their Microsoft access token.
  /// - Parameters:
  ///   - microsoftAccessToken: The user's Microsoft access token.
  public static func getXBoxLiveToken(_ microsoftAccessToken: String) async throws -> XboxLiveToken {
    let payload = XboxLiveAuthenticationRequest(
      properties: XboxLiveAuthenticationRequest.Properties(
        authMethod: "RPS",
        siteName: "user.auth.xboxlive.com",
        accessToken: "\(microsoftAccessToken)"),
      relyingParty: "http://auth.xboxlive.com",
      tokenType: "JWT")
    
    let data: Data
    do {
      let (_, response) = try await RequestUtil.performJSONRequest(
        url: xboxLiveAuthenticationURL,
        body: payload,
        method: .post)
      data = response
    } catch {
      throw MicrosoftAPIError.requestFailed(error)
    }
    
    guard let response = try? ZippyJSONDecoder().decode(XboxLiveAuthenticationResponse.self, from: data) else {
      throw MicrosoftAPIError.failedToDeserializeResponse(String(data: data, encoding: .utf8) ?? "")
    }
    
    guard let userHash = response.displayClaims.xui.first?.userHash else {
      throw MicrosoftAPIError.noUserHashInResponse
    }
    
    return XboxLiveToken(token: response.token, userHash: userHash)
  }
  
  /// Gets the user's XSTS token from their Xbox Live token.
  /// - Parameters:
  ///   - xboxLiveToken: The user's Xbox Live token.
  public static func getXSTSToken(_ xboxLiveToken: String) async throws -> String {
    let payload = XSTSAuthenticationRequest(
      properties: XSTSAuthenticationRequest.Properties(
        sandboxId: xstsSandboxId,
        userTokens: [xboxLiveToken]),
      relyingParty: xstsRelyingParty,
      tokenType: "JWT")
    
    let data: Data
    do {
      let (_, response) = try await RequestUtil.performJSONRequest(
        url: xstsAuthenticationURL,
        body: payload,
        method: .post)
      data = response
    } catch {
      throw MicrosoftAPIError.requestFailed(error)
    }
      
    guard let response = try? ZippyJSONDecoder().decode(XSTSAuthenticationResponse.self, from: data) else {
      if let error = try? ZippyJSONDecoder().decode(XSTSAuthenticationError.self, from: data) {
        throw MicrosoftAPIError.xstsAuthenticationFailed(error)
      }
      
      throw MicrosoftAPIError.failedToDeserializeResponse(String(data: data, encoding: .utf8) ?? "")
    }
    
    return response.token
  }
  
  /// Gets the Minecraft access token from the user's XSTS token.
  /// - Parameters:
  ///   - xstsToken: The user's XSTS token.
  ///   - userHash: The user's hash.
  public static func getMinecraftAccessToken(_ xstsToken: String, _ userHash: String) async throws -> String {
    let payload = MinecraftXboxAuthenticationRequest(
      identityToken: "XBL3.0 x=\(userHash);\(xstsToken)")
    
    let data: Data
    do {
      let (_, response) = try await RequestUtil.performJSONRequest(
        url: minecraftXboxAuthenticationURL,
        body: payload,
        method: .post)
      data = response
    } catch {
      throw MicrosoftAPIError.requestFailed(error)
    }
    
    guard let response = try? ZippyJSONDecoder().decode(MinecraftXboxAuthenticationResponse.self, from: data) else {
      throw MicrosoftAPIError.failedToDeserializeResponse(String(data: data, encoding: .utf8) ?? "")
    }
    
    return response.accessToken
  }
  
  /// Gets the license attached to an account.
  /// - Parameters:
  ///   - accessToken: Access token of account.
  public static func getAttachedLicenses(_ accessToken: String) async throws -> [GameOwnershipResponse.License] {
    var request = Request(gameOwnershipURL)
    request.method = .get
    request.headers["Authorization"] = "Bearer \(accessToken)"
    
    let data: Data
    do {
      let (_, response) = try await RequestUtil.performRequest(request)
      data = response
    } catch {
      throw MicrosoftAPIError.requestFailed(error)
    }
    
    guard let response = try? ZippyJSONDecoder().decode(GameOwnershipResponse.self, from: data) else {
      throw MicrosoftAPIError.failedToDeserializeResponse(String(data: data, encoding: .utf8) ?? "")
    }
        
    return response.items
  }
}
