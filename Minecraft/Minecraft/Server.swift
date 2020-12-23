//
//  Server.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/12/20.
//

import Foundation

class Server: Hashable, ObservableObject {
  var eventManager: EventManager
  var name: String
  var host: String
  var port: Int
  
  @Published var pingInfo: PingInfo?
  var serverConnection: ServerConnection?
  
  init(name: String, host: String, port: Int) {
    self.name = name
    self.host = host
    self.port = port
    self.eventManager = EventManager()
    registerEventHandlers()
    ping()
  }
  
  func registerEventHandlers() {
    eventManager.registerEventHandler(handleStatusResponse, eventNames: ["statusResponse"])
    eventManager.registerEventHandler(handleLoginSuccess, eventNames: ["loginSuccess"])
    
    serverConnection!.registerEventHandlers(eventManager)
  }
  
  func handleStatusResponse(_ event: EventManager.Event) {
    switch event {
      case let .statusResponse(pingInfo):
        self.pingInfo = pingInfo
      default:
        break
    }
  }
  
  func handleLoginSuccess(_ event: EventManager.Event) {
    switch event {
      case .loginSuccess:
        print("login success")
      default:
        break
    }
  }
  
  func ping() {
    createConnection()
    serverConnection!.ping { (pingResult) in
      // @Published value needs to be updated in the main thread
      DispatchQueue.main.async {
        self.pingInfo = pingResult
      }
    }
  }
  
  // just a prototype for later
  func login() {
    createConnection()
    serverConnection!.start() {
      self.serverConnection!.handshake(nextState: .login) {
        let loginStart = LoginStart(username: "stampy654")
        self.serverConnection!.sendPacket(loginStart, callback: .contentProcessed({
          (error) in
          print("done")
        }))
      }
    }
  }
  
  func createConnection() {
    serverConnection = ServerConnection(host: host, port: port)
    serverConnection!.closeCallback = {
      self.serverConnection = nil
      print("\(self.host):\(self.port) closed")
    }
  }
  
  func closeConnection() {
    if (self.serverConnection != nil) {
      serverConnection!.close()
    }
  }
  
  // Things so that SwiftUI ForEach loop works
  static func == (lhs: Server, rhs: Server) -> Bool {
    return (lhs.name == rhs.name && lhs.host == rhs.host && lhs.port == rhs.port)
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(host)
    hasher.combine(port)
  }
}
