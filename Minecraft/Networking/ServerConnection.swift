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
  var queue: DispatchQueue
  var packetHandlers: [ConnectionState: PacketHandler]
  
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
  
  struct ReceiveState {
    var lengthBytes: [UInt8]
    var length: Int
    var packet: [UInt8]
  }
  
  init(host: String, port: Int, eventManager: EventManager) {
    self.host = host
    self.port = port
    self.eventManager = eventManager
    
    self.packetHandlers = type(of: self).createPacketHandlers(withEventManager: eventManager)
    self.logger = Logger(for: type(of: self), desc: "\(host):\(port)")
    
    self.queue = DispatchQueue(label: "networkUpdates")
    self.connection = NWConnection(host: NWEndpoint.Host(self.host), port: NWEndpoint.Port(rawValue: UInt16(self.port))!, using: .tcp)
    
    self.connection.stateUpdateHandler = self.stateUpdateHandler
  }
  
  static func createPacketHandlers(withEventManager eventManager: EventManager) -> [ConnectionState: PacketHandler] {
    var packetHandlers: [ConnectionState: PacketHandler] = [:]
    
    packetHandlers[.status] = StatusHandler(eventManager: eventManager)
//    packetHandlers[.login] = LoginHandler(eventManager: eventManager)
    return packetHandlers
  }
  
  private func stateUpdateHandler(newState: NWConnection.State) {
    switch(newState) {
      case .ready:
        state = .ready
        eventManager.triggerEvent(event: .connectionReady)
        
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
  
  func start() {
    state = .connecting
    connection.start(queue: queue)
  }
  
  // TODO: stop doing so many duplicate cancels
  func close() {
    connection.cancel()
    state = .disconnected
    eventManager.triggerEvent(event: .connectionClosed)
  }
  
  func ping() {
    switch state {
      case .idle:
        eventManager.registerOneTimeEventHandler({ (event) in
          self.ping()
        }, eventName: "connectionReady")
        start()
      case .connecting, .ready:
        handshake(nextState: .status, callback: {
          self.ping()
        })
      case .status:
        let statusRequest = StatusRequest()
        sendPacket(statusRequest)
      default:
        logger.debug("ping in unhandled state")
        break
    }
  }
  
  func handshake(nextState: Handshake.NextState, callback: @escaping () -> Void = {}) {
    state = .handshaking
    let handshake = Handshake(protocolVersion: 754, serverAddr: host, serverPort: port, nextState: nextState)

    self.sendPacket(handshake, callback: .contentProcessed({ (error) in
      if error != nil {
        self.logger.error("failed to send packet: \(error!.debugDescription)")
      }
      self.state = (nextState == .login) ? .login : .status
      callback()
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
              // TODO: might cause thousands of threads again, use a thread pool instead
              let packetCopy = packet
              self.queue.async {
                self.handlePacket(bytes: packetCopy)
              }
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
  
  // bytes doesn't include the length of the packet
  func handlePacket(bytes: [UInt8]) {
    let packetReader = PacketReader(bytes: bytes)
    
    logger.debug("packet received with id: \(packetReader.packetId)")
    
    // NOTE: delete when disconnect packets are handled
    if packetReader.packetId == 0x19 {
      logger.error("received disconnect packet")
      eventManager.triggerError("received disconnect packet")
    }
    
    let packetHandler = packetHandlers[state]
    if packetHandler != nil {
      packetHandler!.handlePacket(packetReader: packetReader)
    } else {
      logger.notice("received packet in invalid or non-implented state")
    }
  }
  
  private func handleNWError(_ error: NWError) {
    if (error == NWError.posix(.ECONNREFUSED) || error == NWError.posix(.ECANCELED)) {
      close()
    } else if error == NWError.dns(-65554) { // -65554 is the error code for NoSuchRecord
      logger.error("no such record: this server is not yet supported as it uses SRV records")
    } else {
      logger.notice("\(String(describing: error))")
    }
  }
}
