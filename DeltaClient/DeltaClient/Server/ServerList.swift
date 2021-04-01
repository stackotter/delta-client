//
//  ServerList.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/12/20.
//

import Foundation

class ServerList: ObservableObject {
  var managers: Managers
  @Published var servers: [ServerPinger] = []
  
  init(managers: Managers) {
    self.managers = managers
  }
  
  func addServer(_ serverDescriptor: ServerDescriptor) {
    let server = ServerPinger(serverDescriptor, managers: managers)
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
