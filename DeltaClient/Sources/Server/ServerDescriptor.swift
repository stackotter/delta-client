//
//  ServerDescriptor.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 20/1/21.
//

import Foundation

struct ServerDescriptor: Equatable, Hashable, Codable {
  var name: String
  var host: String
  var port: UInt16
  
  init(name: String, host: String, port: UInt16) {
    self.name = name
    self.host = host
    self.port = port
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(host)
    hasher.combine(port)
  }
}
