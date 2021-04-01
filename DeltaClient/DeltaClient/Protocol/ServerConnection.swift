//
//  ServerConnection.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 12/12/20.
//

import Foundation
import Network
import os

class ServerConnection {
  var host: String
  var port: UInt16
  var networkStack: NetworkStack
  
  var packetHandlingThread: PacketHandlingThread
  
  var managers: Managers
  var packetRegistry: PacketRegistry
  
  var connectionState: ConnectionState = .idle
  var state: PacketState = .handshaking
  
  // used in the packet receiving loop because of chunking
  struct ReceiveState {
    var lengthBytes: [UInt8]
    var length: Int
    var packet: [UInt8]
  }
  
  init(host: String, port: UInt16, managers: Managers) {
    self.managers = managers
    
    self.host = host
    self.port = port
    
    self.packetRegistry = PacketRegistry.createDefault()
    
    self.networkStack = NetworkStack(host, port, eventManager: self.managers.eventManager)
    
    self.packetHandlingThread = PacketHandlingThread(managers: managers, packetRegistry: self.packetRegistry)
  }
  
  func setHandler(_ handler: @escaping (PacketReader) -> Void) {
    self.networkStack.setPacketHandler(handler)
  }
  
  func restart() {
//    networkStack.restart()
    networkStack.connect()
  }
  
  func sendPacket(_ packet: ServerboundPacket) {
    Logger.log("send packet")
    networkStack.sendPacket(packet)
  }
  
  func start() {
    connectionState = .connecting
    networkStack.connect()
    connectionState = .ready
    Logger.log("start network stack")
  }
  
  func close() {
    connectionState = .disconnected
    networkStack.disconnect()
    managers.eventManager.triggerEvent(.connectionClosed)
  }
  
  func handshake(nextState: HandshakePacket.NextState, callback: @escaping () -> Void = {}) {
    state = .handshaking
    // move protocol version to config or constants file of some sort
    let handshake = HandshakePacket(protocolVersion: PROTOCOL_VERSION, serverAddr: host, serverPort: Int(port), nextState: nextState)

    self.sendPacket(handshake)
    self.state = (nextState == .login) ? .login : .status
    callback()
  }
}
