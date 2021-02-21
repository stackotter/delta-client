//
//  ServerConnection.swift
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
  var socket: NWConnection
  var networkQueue: DispatchQueue
  
  var packetHandlingThread: PacketHandlingThread
  
  var eventManager: EventManager
  var locale: MinecraftLocale
  var packetRegistry: PacketRegistry
  
  var connectionState: ConnectionState = .idle
  var serverState: PacketState = .handshaking
  
  // used in the packet receiving loop because of chunking
  struct ReceiveState {
    var lengthBytes: [UInt8]
    var length: Int
    var packet: [UInt8]
  }
  
  init(host: String, port: Int, eventManager: EventManager, locale: MinecraftLocale) {
    self.host = host
    self.port = port
    self.eventManager = eventManager
    self.locale = locale
    
    self.packetRegistry = PacketRegistry.createDefault()
    
    self.networkQueue = DispatchQueue(label: "networkUpdates")
    self.socket = ServerConnection.createNWConnection(fromHost: self.host, andPort: self.port)
    
    self.packetHandlingThread = PacketHandlingThread(eventManager: eventManager, locale: self.locale, packetRegistry: self.packetRegistry)
  }
  
  func setHandler(_ handler: @escaping (PacketReader, PacketState) -> Void) {
    packetHandlingThread.setHandler(handler)
  }
  
  private func stateUpdateHandler(newState: NWConnection.State) {
    switch(newState) {
      case .ready:
        connectionState = .ready
        eventManager.triggerEvent(.connectionReady)
        receive()
      case .waiting(let error):
        handleNWError(error)
      case .failed(let error):
        connectionState = .disconnected
        handleNWError(error)
      default:
        break
    }
  }
  
  static func createNWConnection(fromHost host: String, andPort port: Int) -> NWConnection{
    return NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: UInt16(port))!, using: .tcp)
  }
  
  func restart() {
    if connectionState != .disconnected {
      socket.forceCancel()
    }
    connectionState = .idle
    socket = ServerConnection.createNWConnection(fromHost: host, andPort: port)
    start()
  }
  
  func start() {
    connectionState = .connecting
    socket.stateUpdateHandler = stateUpdateHandler
    socket.start(queue: networkQueue)
  }
  
  func close() {
    if socket.state != .cancelled {
      self.socket.forceCancel()
    }
    connectionState = .disconnected
    eventManager.triggerEvent(.connectionClosed)
  }
  
  func handshake(nextState: HandshakePacket.NextState, callback: @escaping () -> Void = {}) {
    serverState = .handshaking
    // move protocol version to config or constants file of some sort
    let handshake = HandshakePacket(protocolVersion: PROTOCOL_VERSION, serverAddr: host, serverPort: port, nextState: nextState)

    self.sendPacket(handshake, callback: .contentProcessed({ (error) in
      if error != nil {
        Logger.error("failed to send packet: \(error!.debugDescription)")
      } else {
        self.serverState = (nextState == .login) ? .login : .status
        callback()
      }
    }))
  }
  
  func sendPacket(_ packet: ServerboundPacket, callback: NWConnection.SendCompletion = .idempotent) {
    var writer = PacketWriter()
    writer.writeVarInt(Int32(packet.id))
    packet.writePayload(to: &writer)
    
    sendRaw(bytes: writer.pack(), callback: callback)
  }
  
  func sendRaw(bytes: [UInt8], callback: NWConnection.SendCompletion = .idempotent) {
    let data = Data(bytes)
    socket.send(content: data, completion: callback)
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
    socket.receive(minimumIncompleteLength: 0, maximumLength: 4096, completion: {
      (data, context, isComplete, error) in
      if data == nil {
        return
      } else if error != nil {
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
          Logger.info("received empty packet")
          length = -1
          lengthBytes = []
        } else if (length != -1 && buf.remaining != 0) {
          while buf.remaining != 0 {
            let byte = buf.readByte()
            packet.append(byte)
            
            if (packet.count == length) {
              self.packetHandlingThread.handleBytes(packet, state: self.serverState)
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
      
      if (self.socket.state == .ready) {
        let receiveState = ReceiveState(lengthBytes: lengthBytes, length: length, packet: packet)
        self.receive(receiveState: receiveState)
      } else {
        Logger.debug("stopped receiving")
      }
    })
  }
  
  private func handleNWError(_ error: NWError) {
    if error == NWError.posix(.ECONNREFUSED) {
      Logger.error("connection refused (\(self.host):\(self.port))")
    } else if error == NWError.posix(.ECANCELED) {
      // do nothing
    } else if error == NWError.dns(-65554) { // -65554 is the error code for NoSuchRecord
      Logger.error("no such record: this server is not yet supported as it uses SRV records (\(self.host):\(self.port))")
    } else if connectionState != .disconnected {
//      Logger.debug("\(String(describing: error))")
    }
  }
}
