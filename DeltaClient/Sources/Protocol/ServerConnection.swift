//
//  ServerConnection.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 12/12/20.
//

import Foundation
import Network


class ServerConnection {
  var host: String
  var port: UInt16
  
  var eventManager: EventManager<ServerEvent>
  var packetRegistry: PacketRegistry
  var networkStack: NetworkStack
  
  var state: ConnectionState
  
  enum ConnectionState {
    case idle
    case handshaking
    case status
    case login
    case play
    case disconnected
    
    func toPacketState() -> PacketState? {
      switch self {
        case .handshaking:
          return .handshaking
        case .status:
          return .status
        case .login:
          return .login
        case .play:
          return .play
        default:
          return nil
      }
    }
  }
  
  // Init
  
  init(host: String, port: UInt16, eventManager: EventManager<ServerEvent>) {
    self.eventManager = eventManager
    
    self.host = host
    self.port = port
    
    self.packetRegistry = PacketRegistry.createDefault()
    self.networkStack = NetworkStack(host, port, eventManager: self.eventManager)
    
    self.state = .idle
  }
  
  // Lifecycle
  
  func start() {
    networkStack.connect()
  }
  
  func close() {
    networkStack.disconnect()
  }
  
  func restart() {
    networkStack.reconnect()
  }
  
  // Network layers
  
  func setCompression(threshold: Int) {
    networkStack.compressionLayer.compressionThreshold = threshold
  }
  
  func enableEncryption(sharedSecret: [UInt8]) {
    networkStack.encryptionLayer.enableEncryption(sharedSecret: sharedSecret)
  }
  
  // Packet
  
  func setPacketHandler(_ handler: @escaping (PacketReader) -> Void) {
    networkStack.setPacketHandler(handler)
  }
  
  func sendPacket(_ packet: ServerboundPacket) {
    networkStack.sendPacket(packet)
  }
  
  // Abstracted Operations
  
  func handshake(nextState: HandshakePacket.NextState) {
    let handshake = HandshakePacket(protocolVersion: Constants.protocolVersion, serverAddr: host, serverPort: Int(port), nextState: nextState)
    self.sendPacket(handshake)
    self.state = (nextState == .login) ? .login : .status
  }
  
  func login(username: String) {
    eventManager.registerOneTimeEventHandler({ _ in
      self.handshake(nextState: .login)
      
      let loginStart = LoginStartPacket(username: username)
      self.sendPacket(loginStart)
    }, eventName: "connectionReady")
    restart()
  }
}
