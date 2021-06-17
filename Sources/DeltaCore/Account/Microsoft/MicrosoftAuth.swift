//
//  MicrosoftAPI.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 24/4/21.
//

import Foundation

enum MicrosoftAuthError: LocalizedError {
  case invalidRedirectURL
  case noUserHashInResponse
  case failedToSerializeRequest
  case failedToDeserializeResponse
  case xstsAuthenticationFailed(XSTSAuthenticationError)
}

struct MicrosoftAuth {
  static func getAuthorizationURL() -> URL {
    let url = MicrosoftAPIDefinition.authorizationBaseURL.appendingQueryItems([
      "client_id": MicrosoftAPIDefinition.clientId,
      "response_type": "code",
      "scope": "XboxLive.signin offline_access"
    ])
    
    return url
  }
  
  static func codeFromRedirectURL(_ url: URL) throws -> String {
    if let components = URLComponents(string: url.absoluteString) {
      if let queryItems = components.queryItems {
        for item in queryItems {
          if item.name == "code",
             let code = item.value{
            return code
          }
        }
      }
    }
    throw MicrosoftAuthError.invalidRedirectURL
  }
  
  static func getMicrosoftAccessToken(
    authorizationCode: String,
    onCompletion: @escaping (_ token: String) -> Void,
    onFailure: @escaping (_ error: Error) -> Void)
  {
    let payload = RequestUtil.encodeParameters([
      "client_id": MicrosoftAPIDefinition.clientId,
      "code": authorizationCode,
      "grant_type": "authorization_code"
    ])
    
    guard let body = payload.data(using: .utf8) else {
      onFailure(MicrosoftAuthError.failedToSerializeRequest)
      return
    }
    
    var request = Request(MicrosoftAPIDefinition.authenticationURL)
    request.method = .post
    request.contentType = .form
    request.body = body
    
    RequestUtil.perform(request, onCompletion: { _, data in
      guard let response = try? JSONDecoder().decode(MicrosoftAccessTokenResponse.self, from: data) else {
        onFailure(MicrosoftAuthError.failedToDeserializeResponse)
        return
      }
    
      onCompletion(response.accessToken)
    }, onFailure: onFailure)
  }
  
  static func getXBoxLiveToken(
    _ microsoftAccessToken: String,
    onCompletion: @escaping (_ token: String, _ userHash: String) -> Void,
    onFailure: @escaping (_ error: Error) -> Void)
  {
    let payload = XboxLiveAuthenticationRequest(
      properties: XboxLiveAuthenticationRequest.Properties(
        authMethod: "RPS",
        siteName: "user.auth.xboxlive.com",
        accessToken: "d=\(microsoftAccessToken)"),
      relyingParty: "http://auth.xboxlive.com",
      tokenType: "JWT")
    
    guard let body = try? JSONEncoder().encode(payload) else {
      onFailure(MicrosoftAuthError.failedToSerializeRequest)
      return
    }
    
    var request = Request(MicrosoftAPIDefinition.xboxLiveAuthenticationURL)
    request.method = .post
    request.contentType = .json
    request.body = body
    
    RequestUtil.perform(request, onCompletion: { _, data in
      guard let response = try? JSONDecoder().decode(XboxLiveAuthenticationResponse.self, from: data) else {
        onFailure(MicrosoftAuthError.failedToDeserializeResponse)
        return
      }
      
      if let userHash = response.displayClaims.xui.first?.userHash {
        onCompletion(response.token, userHash)
      } else {
        onFailure(MicrosoftAuthError.noUserHashInResponse)
      }
    }, onFailure: onFailure)
  }
  
  static func getXSTSToken(
    _ xboxLiveToken: String,
    onCompletion: @escaping (_ token: String) -> Void,
    onFailure: @escaping (_ error: Error) -> Void)
  {
    let payload = XSTSAuthenticationRequest(
      properties: XSTSAuthenticationRequest.Properties(
        sandboxId: MicrosoftAPIDefinition.xstsSandboxId,
        userTokens: [xboxLiveToken]),
      relyingParty: MicrosoftAPIDefinition.xstsRelyingParty, tokenType: "JWT")
    
    guard let body = try? JSONEncoder().encode(payload) else {
      onFailure(MicrosoftAuthError.failedToSerializeRequest)
      return
    }
    
    var request = Request(MicrosoftAPIDefinition.xstsAuthenticationURL)
    request.method = .post
    request.contentType = .json
    request.body = body
    
    RequestUtil.perform(request, onCompletion: { _, data in
      guard let response = try? JSONDecoder().decode(XSTSAuthenticationResponse.self, from: data) else {
        if let error = try? JSONDecoder().decode(XSTSAuthenticationError.self, from: data) {
          onFailure(MicrosoftAuthError.xstsAuthenticationFailed(error))
        } else {
          onFailure(MicrosoftAuthError.failedToDeserializeResponse)
        }
        return
      }
      
      onCompletion(response.token)
    }, onFailure: onFailure)
  }
  
  static func getMinecraftAccessToken(
    _ xstsToken: String,
    _ userHash: String,
    onCompletion: @escaping (_ token: String) -> Void,
    onFailure: @escaping (_ error: Error) -> Void)
  {
    let payload = MinecraftXboxAuthenticationRequest(
      identityToken: "XBL3.0 x=\(userHash);\(xstsToken)")
    
    guard let body = try? JSONEncoder().encode(payload) else {
      onFailure(MicrosoftAuthError.failedToSerializeRequest)
      return
    }
    
    var request = Request(MicrosoftAPIDefinition.minecraftXboxAuthenticationURL)
    request.method = .post
    request.contentType = .json
    request.body = body
    
    RequestUtil.perform(request, onCompletion: { _, data in
      guard let response = try? JSONDecoder().decode(MinecraftXboxAuthenticationResponse.self, from: data) else {
        onFailure(MicrosoftAuthError.failedToDeserializeResponse)
        return
      }
      
      onCompletion(response.accessToken)
    }, onFailure: onFailure)
  }
  
  static func getAttachedLicenses(
    _ accessToken: String,
    onCompletion: @escaping (_ licenses: [GameOwnershipResponse.License]) -> Void,
    onFailure: @escaping (_ error: Error) -> Void)
  {
    var request = Request(MicrosoftAPIDefinition.gameOwnershipURL)
    request.method = .get
    request.headers["Authorization"] = "Bearer \(accessToken)"
    
    RequestUtil.perform(request, onCompletion: { _, data in
      guard let response = try? JSONDecoder().decode(GameOwnershipResponse.self, from: data) else {
        onFailure(MicrosoftAuthError.failedToDeserializeResponse)
        return
      }
      
      onCompletion(response.items)
    }, onFailure: onFailure)
  }
}
