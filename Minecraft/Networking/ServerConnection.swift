//
//  Socket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 12/12/20.
//

import Foundation
import Network
import os

class ServerConnection {
  var host: String
  var port: Int
  var connection: NWConnection
  var networkQueue: DispatchQueue
  
  var packetHandlingPool: PacketHandlerThreadPool
  
  var eventManager: EventManager
  var logger: Logger
  
  var state: ConnectionState = .idle
  
  enum ConnectionState {
    case idle
    case connecting
    case ready
    case handshaking
    case status
    case login
    case play
    case disconnected
  }
  
  // used in the packet receiving loop because of chunking
  struct ReceiveState {
    var lengthBytes: [UInt8]
    var length: Int
    var packet: [UInt8]
  }
  
  init(host: String, port: Int, eventManager: EventManager) {
    self.host = host
    self.port = port
    self.eventManager = eventManager
    
    self.logger = Logger(for: type(of: self), desc: "\(host):\(port)")
    
    self.networkQueue = DispatchQueue(label: "networkUpdates")
    self.connection = ServerConnection.createNWConnection(fromHost: self.host, andPort: self.port)
    
    self.packetHandlingPool = PacketHandlerThreadPool(eventManager: eventManager)
  }
  
  func registerPacketHandlers(handlers: [ServerConnection.ConnectionState: PacketHandler]) {
    packetHandlingPool.packetHandlers = handlers
  }
  
  private func stateUpdateHandler(newState: NWConnection.State) {
    switch(newState) {
      case .ready:
        state = .ready
        eventManager.triggerEvent(.connectionReady)
        receive()
      case .waiting(let error):
        handleNWError(error)
      case .failed(let error):
        state = .disconnected
        logger.error("failed to start connection to server")
        handleNWError(error)
      default:
        break
    }
  }
  
  static func createNWConnection(fromHost host: String, andPort port: Int) -> NWConnection{
    return NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: UInt16(port))!, using: .tcp)
  }
  
  func restart() {
    if state != .disconnected {
      connection.forceCancel()
    }
    state = .idle
    connection = ServerConnection.createNWConnection(fromHost: host, andPort: port)
    start()
  }
  
  func start() {
    state = .connecting
    connection.stateUpdateHandler = stateUpdateHandler
    connection.start(queue: networkQueue)
  }
  
  func close() {
    if connection.state != .cancelled {
      self.connection.forceCancel()
    }
    state = .disconnected
    eventManager.triggerEvent(.connectionClosed)
  }
  
  func handshake(nextState: Handshake.NextState, callback: @escaping () -> Void = {}) {
    state = .handshaking
    // move protocol version to config or constants file of some sort
    let handshake = Handshake(protocolVersion: PROTOCOL_VERSION, serverAddr: host, serverPort: port, nextState: nextState)

    self.sendPacket(handshake, callback: .contentProcessed({ (error) in
      if error != nil {
        self.logger.error("failed to send packet: \(error!.debugDescription)")
      } else {
        self.state = (nextState == .login) ? .login : .status
        callback()
      }
    }))
  }
  
  func sendPacket<T: Packet>(_ packet: T, callback: NWConnection.SendCompletion = .idempotent) {
    sendRaw(bytes: packet.toBytes(), callback: callback)
  }
  
  func sendRaw(bytes: [UInt8], callback: NWConnection.SendCompletion = .idempotent) {
    let data = Data(bytes)
    connection.send(content: data, completion: callback)
  }
  
  private func receive(receiveState: ReceiveState? = nil) {
    var lengthBytes: [UInt8] = []
    var length: Int = -1
    var packet: [UInt8] = []
    if receiveState != nil {
      lengthBytes = receiveState!.lengthBytes
      length = receiveState!.length
      packet = receiveState!.packet
    }
    connection.receive(minimumIncompleteLength: 0, maximumLength: 4096, completion: {
      (data, context, isComplete, error) in
      if (isComplete) {
        self.close()
        return
      } else if (error != nil) {
        self.handleNWError(error!)
        return
      }
      
      let bytes = [UInt8](data!)
      var buf = Buffer(bytes)
      
      while true {
        if (length == -1) {
          while buf.remaining != 0 {
            let byte = buf.readByte()
            lengthBytes.append(byte)
            if (byte & 0x80 == 0x00) {
              break
            }
          }
          
          if (lengthBytes.count != 0) {
            if (lengthBytes.last! & 0x80 == 0x00) {
              // using standalone implementation of varint decoding to hopefully reduce networking overheads slightly?
              length = 0
              for i in 0..<lengthBytes.count {
                let byte = lengthBytes[i]
                length += Int(byte & 0x7f) << (i * 7)
              }
            }
          }
        }
        
        if (length == 0) {
          self.logger.info("received empty packet")
          length = -1
          lengthBytes = []
        } else if (length != -1 && buf.remaining != 0) {
          while buf.remaining != 0 {
            let byte = buf.readByte()
            packet.append(byte)
            
            if (packet.count == length) {
              self.packetHandlingPool.handleBytes(packet, state: self.state)
              packet = []
              length = -1
              lengthBytes = []
              break
            }
          }
        }
        
        if (buf.remaining == 0) {
          break
        }
      }
      
      if (self.connection.state == .ready) {
        let receiveState = ReceiveState(lengthBytes: lengthBytes, length: length, packet: packet)
        self.receive(receiveState: receiveState)
      } else {
        self.logger.debug("stopped receiving")
      }
    })
  }
  
  private func handleNWError(_ error: NWError) {
    if error == NWError.posix(.ECONNREFUSED) {
      logger.error("connection refused")
    } else if error == NWError.posix(.ECANCELED) {
      // do nothing
    } else if error == NWError.dns(-65554) { // -65554 is the error code for NoSuchRecord
      logger.error("no such record: this server is not yet supported as it uses SRV records")
    } else {
      logger.notice("\(String(describing: error))")
    }
  }
}
