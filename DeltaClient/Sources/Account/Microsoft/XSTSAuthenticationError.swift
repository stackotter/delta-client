//
//  XSTSAuthenticationErrorResponse.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 24/4/21.
//

import Foundation

struct XSTSAuthenticationError: Codable {
  var identity: String
  var code: Int
  var message: String
  var redirect: String
  
  private enum CodingKeys: String, CodingKey {
    case identity = "Identity"
    case code = "XErr"
    case message = "Message"
    case redirect = "Redirect"
  }
}
