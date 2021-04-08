//
//  ServerList.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/12/20.
//

import Foundation

class ServerList: ObservableObject {
  @Published var pingers: [ServerPinger] = []
  
  init(_ descriptors: [ServerDescriptor]) {
    for descriptor in descriptors {
      addServer(descriptor)
    }
    refresh()
  }
  
  func addServer(_ descriptor: ServerDescriptor) {
    let server = ServerPinger(descriptor)
    pingers.append(server)
  }
  
  func refresh() {
    for pinger in pingers {
      DispatchQueue.main.async {
        pinger.ping()
      }
    }
  }
}
