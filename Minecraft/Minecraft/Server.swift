//
//  Server.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/12/20.
//

import Foundation
import os

class Server: Hashable, ObservableObject {
  var eventManager: EventManager
  var serverEventManager: EventManager
  var name: String
  var host: String
  var port: Int
  
  var logger: Logger
  
  @Published var pingInfo: PingInfo?
  var serverConnection: ServerConnection?
  
  init(name: String, host: String, port: Int, eventManager: EventManager) {
    self.name = name
    self.host = host
    self.port = port
    self.eventManager = eventManager
    self.serverEventManager = EventManager()
    self.logger = Logger(for: type(of: self), desc: "\(host):\(port)")
    
    registerEventHandlers()
    ping()
  }
  
  func registerEventHandlers() {
    serverEventManager.registerEventHandler(handlePingInfoReceived, eventNames: ["pingInfoReceived"])
    serverEventManager.registerEventHandler(handleLoginSuccess, eventNames: ["loginSuccess"])
    serverEventManager.registerEventHandler(handleConnectionClosed, eventNames: ["connectionClosed"])
    serverEventManager.registerEventHandler(handleError, eventNames: ["error"])
  }
  
  func handleError(_ event: EventManager.Event) {
    switch event {
      case var .error(message):
        message = "[\(host):\(port)] \(message)"
        eventManager.triggerError(message)
        logger.debug("escalated error to app wide event manager")
      default:
        break
    }
  }
  
  func handlePingInfoReceived(_ event: EventManager.Event) {
    logger.debug("received ping info")
    switch event {
      case let .pingInfoReceived(pingInfo):
        DispatchQueue.main.sync {
          self.pingInfo = pingInfo
        }
        serverConnection?.close()
      default:
        break
    }
  }
  
  func handleLoginSuccess(_ event: EventManager.Event) {
    logger.debug("login success")
  }
  
  func handleConnectionClosed(_ event: EventManager.Event) {
    logger.debug("connection closed")
    self.serverConnection = nil
  }
  
  func createConnection() {
    logger.debug("created connection")
    serverConnection = ServerConnection(host: host, port: port, eventManager: serverEventManager)
  }
  
  func ping() {
    pingInfo = nil
    createConnection()
    serverConnection!.ping()
  }
  
  // just a prototype for later
  func login() {
    createConnection()
    serverEventManager.registerOneTimeEventHandler({
      (event) in
      self.serverConnection!.handshake(nextState: .login) {
        let loginStart = LoginStart(username: "stampy654")
        self.serverConnection!.sendPacket(loginStart, callback: .contentProcessed({
          (error) in
          self.logger.debug("sent login start packet")
        }))
      }
    }, eventName: "connectionReady")
    serverConnection!.start()
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
