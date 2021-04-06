//
//  MojangAPI.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/4/21.
//

import Foundation
import os

// TODO: handle errors in api response using status code (403)
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
        Logger.error("failed to authenticate mojang account '\(email)', \(error!)")
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
}
