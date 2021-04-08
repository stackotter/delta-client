//
//  MojangAPI.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/4/21.
//

import Foundation
import os

// TODO: make these throwing
// TODO: handle errors in api response using status code (403)
// TODO: clean up api
struct MojangAPI {
  static func login(email: String, password: String, clientToken: String, completion: @escaping (MojangAuthenticationResponse) -> ()){
    let requestObject = MojangAuthenticationRequest(
      agent: MojangAgent(),
      username: email,
      password: password,
      clientToken: clientToken,
      requestUser: true
    )
    
    let encoder = JSONEncoder()
    let requestBody: Data
    do {
      requestBody = try encoder.encode(requestObject)
    } catch {
      Logger.error("failed to serialise mojang authentication request, \(error)")
      return
    }
    
    RequestUtil.post(MojangAPIDefinition.AUTHENTICATION_URL, requestBody) { data, error in
      if error != nil {
        Logger.error("failed to authenticate mojang account '\(email)': \(error!)")
      } else if let jsonData = data {
        do {
          let response = try JSONDecoder().decode(MojangAuthenticationResponse.self, from: jsonData)
          completion(response)
        } catch {
          Logger.error("failed to parse mojang authentication response, \(error)")
        }
      } else {
        Logger.error("failed to authenticate mojang account '\(email)', no response body")
      }
    }
  }
  
  // TODO: a lot of repeated code in these functions
  static func join(accessToken: String, selectedProfile: String, serverHash: String, completion: @escaping () -> ()) {
    let requestObject = MojangJoinRequest(
      accessToken: accessToken,
      selectedProfile: selectedProfile,
      serverId: serverHash
    )
    
    let encoder = JSONEncoder()
    let requestBody: Data
    do {
      requestBody = try encoder.encode(requestObject)
    } catch {
      Logger.error("failed to serialise mojang join request, \(error)")
      return
    }
    
    RequestUtil.post(MojangAPIDefinition.JOIN_SERVER_URL, requestBody) { data, error in
      if error != nil {
        Logger.error("mojang api join request failed: \(error!)")
      } else {
        completion()
      }
      // TODO: check status code of response
    }
  }
  
  static func refresh(accessToken: String, clientToken: String, completion: @escaping (_ accessToken: String) -> (), failure: @escaping () -> ()) throws {
    let requestObject = [
      "accessToken": accessToken,
      "clientToken": clientToken
    ]
    
    let requestBody = try JSONSerialization.data(withJSONObject: requestObject, options: [])
    
    RequestUtil.post(MojangAPIDefinition.REFRESH_URL, requestBody) { data, error in
      if error != nil {
        Logger.error("mojang token refresh failed: \(error!)")
        // TODO: trigger re-login?
      } else {
        do {
          let response = try JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
          if let newAccessToken = response["accessToken"] as? String {
            completion(newAccessToken)
          } else {
            Logger.error("failed to refresh access token: \(response["errorMessage"] ?? "no error message provided")")
            failure()
          }
        } catch {
          Logger.error("invalid response from server")
        }
      }
    }
  }
}
