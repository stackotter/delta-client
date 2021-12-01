import Foundation
import ZippyJSON

public enum MojangAPIError: LocalizedError {
  case failedToSerializeRequest
  case failedToDeserializeResponse
  case requestFailed(Error)
}

// TODO: make these throwing
// TODO: handle errors in api response using status code (403)
// TODO: clean up api
public struct MojangAPI {
  public static func login(
    email: String,
    password: String,
    clientToken: String,
    onCompletion completion: @escaping (_ account: MojangAccount) -> Void,
    onFailure failure: @escaping (_ error: MojangAPIError) -> Void)
  {
    let payload = MojangAuthenticationRequest(
      agent: MojangAgent(),
      username: email,
      password: password,
      clientToken: clientToken,
      requestUser: true
    )
    
    guard let body = try? JSONEncoder().encode(payload) else {
      failure(MojangAPIError.failedToSerializeRequest)
      return
    }
    
    var request = Request(MojangAPIDefinition.authenticationURL)
    request.method = .post
    request.contentType = .json
    request.body = body
    
    RequestUtil.perform(request, onCompletion: { _, data in
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
  
  // TODO: a lot of repeated code in these functions
  public static func join(
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
  
  public static func refresh(
    _ account: MojangAccount,
    with clientToken: String,
    onCompletion completion: @escaping (_ account: MojangAccount) -> Void,
    onFailure failure: @escaping (_ error: Error) -> Void)
  {
    let payload = MojangRefreshTokenRequest(
      accessToken: account.accessToken,
      clientToken: clientToken)
    
    guard let body = try? JSONEncoder().encode(payload) else {
      failure(MojangAPIError.failedToSerializeRequest)
      return
    }
    
    var request = Request(MojangAPIDefinition.refreshURL)
    request.method = .post
    request.contentType = .json
    request.body = body
    
    RequestUtil.perform(request, onCompletion: { _, data in
      guard let response = try? ZippyJSONDecoder().decode(MojangRefreshTokenResponse.self, from: data) else {
        failure(MojangAPIError.failedToDeserializeResponse)
        return
      }
      
      var refreshedAccount = account
      refreshedAccount.accessToken = response.accessToken
      completion(refreshedAccount)
    }, onFailure: failure)
  }
}
