//
//  ServerList.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/12/20.
//

import Foundation

class ServerList: ObservableObject {
  @Published var servers: [ServerPinger] = []
  
  func addServer(_ serverInfo: ServerInfo) {
    let server = ServerPinger(serverInfo)
    servers.append(server)
  }
  
  func refresh() {
    for server in servers {
      DispatchQueue.main.async {
        server.ping()
      }
    }
  }
}
