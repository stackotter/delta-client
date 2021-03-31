//
//  ServerInfo.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 20/1/21.
//

import Foundation

struct ServerInfo: Equatable, Hashable {
  var name: String
  var host: String
  var port: Int
  
  init?(name: String, ip: String) {
    self.name = name
    
    if let url = URL.init(string: "minecraft://\(ip)") {
      if let host = url.host {
        self.host = host
        if let port = url.port {
          self.port = port
        } else {
          self.port = 25565
        }
      } else {
        return nil
      }
    } else {
      return nil
    }
  }
  
  init(name: String, host: String, port: Int) {
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
