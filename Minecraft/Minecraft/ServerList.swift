//
//  ServerList.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/12/20.
//

import Foundation

class ServerList: ObservableObject {
  @Published var servers: [Server]
  
  init(withServers servers: [Server]) {
    self.servers = servers
  }
  
  func refresh() {
    for server in servers {
      DispatchQueue.main.async {
        server.ping()
      }
    }
  }
}
