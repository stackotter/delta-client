//
//  Socket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 12/12/20.
//

import Foundation
import Network

class ServerConnection {
  var host: String
  var port: Int
  var connection: NWConnection
  var queue: DispatchQueue
  var statusHandler: StatusHandler
  
  var readyCallback: () -> Void = {}
  var pingCallback: (PingInfo) -> Void = {
    (pingInfo) in
  }
  var closeCallback: () -> Void = {}
  
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
  
  init(host: String, port: Int) {
    self.host = host
    self.port = port
    self.connection = NWConnection(host: NWEndpoint.Host(self.host), port: NWEndpoint.Port(rawValue: UInt16(self.port))!, using: .tcp)
    
    self.queue = DispatchQueue(label: "networkUpdates")
    
    self.statusHandler = StatusHandler()
    
    self.connection.stateUpdateHandler = stateUpdateHandler
  }
  
  func registerEventHandlers(_ eventManager: EventManager) {
    
  }
  
  func start(callback: @escaping () -> Void = {}) {
    state = .connecting
    readyCallback = callback
    connection.start(queue: queue)
  }
  
  func close() {
    connection.cancel()
    state = .disconnected
    closeCallback()
  }
  
  func ping(callback: ((PingInfo) -> Void)? = nil) {
    statusHandler.pingCallback = callback
    // TODO: change to switch statement
    if (state == .idle) {
      start(callback: {
        self.ping(callback: callback)
      })
    } else if (state == .connecting || state == .ready) {
      handshake(nextState: .status, callback: {
        self.ping(callback: callback)
      })
    } else if (state == .status) {
      let statusRequest = StatusRequest()
      sendPacket(statusRequest)
    }
  }
  
  func handshake(nextState: Handshake.NextState, callback: @escaping () -> Void = {}) {
    state = .handshaking
    let handshake = Handshake(protocolVersion: 754, serverAddr: host, serverPort: port, nextState: nextState)

    // TODO: error handling
    self.sendPacket(handshake, callback: .contentProcessed({ (error) in
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
      var reader = PacketReader(bytes: bytes)
      
      while true {
        if (length == -1) {
          while reader.remaining != 0 {
            let byte = reader.readByte()
            lengthBytes.append(byte)
            if (byte & 0x80 == 0x00) {
              break
            }
          }
          
          if (lengthBytes.count != 0) {
            if (lengthBytes.last! & 0x80 == 0x00) {
              length = 0
              for i in 0..<lengthBytes.count {
                let byte = lengthBytes[i]
                length += Int(byte & 0x7f) << (i * 7)
              }
            }
          }
        }
        
        if (length == 0) {
          self.log("received empty packet")
          length = -1
          lengthBytes = []
        } else if (length != -1 && reader.remaining != 0) {
          while reader.remaining != 0 {
            let byte = reader.readByte()
            packet.append(byte)
            
            if (packet.count == length) {
              // TODO: might cause thousands of threads again
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
        
        if (reader.remaining == 0) {
          break
        }
      }
      
      if (self.connection.state == .ready) {
        let receiveState = ReceiveState(lengthBytes: lengthBytes, length: length, packet: packet)
        self.receive(receiveState: receiveState)
      } else {
        print("this should probably just fail here")
      }
    })
  }
  
  // TODO: delete when proper logger implemented
  func log(_ message: String) {
    print("[INFO] \(self.host):\(String(self.port)) : \(message)")
  }
  
  // bytes doesn't include the length of the packet
  func handlePacket(bytes: [UInt8]) {
    print("packet received with id: \(bytes[0])")
    var reader = PacketReader(bytes: bytes)
    
    // TODO: delete when disconnect packets are handled
    if bytes[0] == 0x19 {
      log("disconnect: \(bytes)")
    }
    
    switch state {
      case .idle, .connecting, .disconnected:
        print("received packet in invalid state")
      case .status:
        statusHandler.handlePacket(reader: reader)
      case .login:
        print(reader.readPacketId())
      default:
        return
    }
  }
  
  private func stateUpdateHandler(newState: NWConnection.State) {
    switch(newState) {
      case .ready:
        state = .ready
        receive()
        readyCallback()
      case .waiting(let error):
        handleNWError(error)
      case .failed(let error):
        state = .disconnected
        print("error: \(error)")
        handleNWError(error)
      default:
        break
    }
  }
  
  private func handleNWError(_ error: NWError) {
    if (error == NWError.posix(.ECONNREFUSED) || error == NWError.posix(.ECANCELED)) {
      close()
    } else {
      print("NWError: \(error)")
    }
  }
}
