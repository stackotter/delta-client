//
//  RequestMethod.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 6/4/21.
//

import Foundation

enum RequestMethod: String {
  case get = "GET"
  case post = "POST"
  case head = "HEAD"
  case put = "PUT"
  case delete = "DELETE"
  case connect = "CONNECT"
  case options = "OPTIONS"
  case trace = "TRACE"
  case patch = "PATCH"
}
