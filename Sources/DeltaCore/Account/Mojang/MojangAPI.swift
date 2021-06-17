//
//  MojangAPI.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 6/4/21.
//

import Foundation

enum MojangAPIError: LocalizedError {
  case failedToSerializeRequest
  case failedToDeserializeResponse
}

// TODO: make these throwing
// TODO: handle errors in api response using status code (403)
// TODO: clean up api
struct MojangAPI {
  static func login(
    email: String,
    password: String,
    clientToken: String,
    onCompletion: @escaping (_ response: MojangAuthenticationResponse) -> Void,
    onFailure: @escaping (_ error: Error) -> Void)
  {
    let payload = MojangAuthenticationRequest(
      agent: MojangAgent(),
      username: email,
      password: password,
      clientToken: clientToken,
      requestUser: true
    )
    
    guard let body = try? JSONEncoder().encode(payload) else {
      onFailure(MojangAPIError.failedToSerializeRequest)
      return
    }
    
    var request = Request(MojangAPIDefinition.authenticationURL)
    request.method = .post
    request.contentType = .json
    request.body = body
    
    RequestUtil.perform(request, onCompletion: { _, data in
      guard let response = try? JSONDecoder().decode(MojangAuthenticationResponse.self, from: data) else {
        onFailure(MojangAPIError.failedToDeserializeResponse)
        return
      }
      
      onCompletion(response)
    }, onFailure: onFailure)
  }
  
  // TODO: a lot of repeated code in these functions
  static func join(
    accessToken: String,
    selectedProfile: String,
    serverHash: String,
    onCompletion: @escaping () -> Void,
    onFailure: @escaping (_ error: Error) -> Void)
  {
    let payload = MojangJoinRequest(
      accessToken: accessToken,
      selectedProfile: selectedProfile,
      serverId: serverHash
    )
    
    guard let body = try? JSONEncoder().encode(payload) else {
      onFailure(MojangAPIError.failedToSerializeRequest)
      return
    }
    
    var request = Request(MojangAPIDefinition.joinServerURL)
    request.method = .post
    request.contentType = .json
    request.body = body
    
    RequestUtil.perform(request, onCompletion: { _, _ in
      // TODO: check status code of response
      onCompletion()
    }, onFailure: onFailure)
  }
  
  static func refresh(
    accessToken: String,
    clientToken: String,
    onCompletion: @escaping (_ accessToken: String) -> Void,
    onFailure: @escaping (_ error: Error) -> Void)
  {
    let payload = MojangRefreshTokenRequest(
      accessToken: accessToken,
      clientToken: clientToken)
    
    guard let body = try? JSONEncoder().encode(payload) else {
      onFailure(MojangAPIError.failedToSerializeRequest)
      return
    }
    
    var request = Request(MojangAPIDefinition.refreshURL)
    request.method = .post
    request.contentType = .json
    request.body = body
    
    RequestUtil.perform(request, onCompletion: { _, data in
      guard let response = try? JSONDecoder().decode(MojangRefreshTokenResponse.self, from: data) else {
        onFailure(MojangAPIError.failedToDeserializeResponse)
        return
      }
      
      onCompletion(response.accessToken)
    }, onFailure: onFailure)
  }
}
