//
//  NetworkStack.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 31/3/21.
//

import Foundation

class NetworkStack {
  var eventManager: EventManager<ServerEvent>
  
  var ioThread: DispatchQueue
  var inboundThread: DispatchQueue
  var outboundThread: DispatchQueue
  
  var host: String
  var port: UInt16
  
  // network layers
  var socketLayer: SocketLayer
  var encryptionLayer: EncryptionLayer
  var packetLayer: PacketLayer
  var compressionLayer: CompressionLayer
  var protocolLayer: ProtocolLayer
  
  // Init
  
  init(_ host: String, _ port: UInt16, eventManager: EventManager<ServerEvent>) {
    self.host = host
    self.port = port
    
    self.eventManager = eventManager
    self.ioThread = DispatchQueue(label: "networkIO")
    self.inboundThread = DispatchQueue(label: "networkHandlingInbound")
    self.outboundThread = DispatchQueue(label: "networkHandlingOutbound")
    
    // create layers
    socketLayer = SocketLayer(host, port, inboundThread: self.inboundThread, ioThread: self.ioThread, eventManager: self.eventManager)
    encryptionLayer = EncryptionLayer()
    packetLayer = PacketLayer()
    compressionLayer = CompressionLayer()
    protocolLayer = ProtocolLayer(outboundThread: self.outboundThread)
    
    // setup inbound flow
    socketLayer.inboundSuccessor = encryptionLayer
    encryptionLayer.inboundSuccessor = packetLayer
    packetLayer.inboundSuccessor = compressionLayer
    compressionLayer.inboundSuccessor = protocolLayer
    
    // setup outbound flow
    protocolLayer.outboundSuccessor = compressionLayer
    compressionLayer.outboundSuccessor = packetLayer
    packetLayer.outboundSuccessor = encryptionLayer
    encryptionLayer.outboundSuccessor = socketLayer
  }
  
  // Lifecycle
  
  func connect() {
    socketLayer.connect()
  }
  
  func disconnect() {
    socketLayer.disconnect()
  }
  
  func reconnect() {
    disconnect()
    
    // remake socket layer
    let socketLayerSuccessor = socketLayer.inboundSuccessor
    socketLayer = SocketLayer(host, port, inboundThread: inboundThread, ioThread: ioThread, eventManager: eventManager)
    socketLayer.inboundSuccessor = socketLayerSuccessor
    if var outboundPredecessor = socketLayer.inboundSuccessor as? OutboundNetworkLayer {
      outboundPredecessor.outboundSuccessor = socketLayer
    }
    
    connect()
  }
  
  // Packet
  
  func setPacketHandler(_ handler: @escaping (ProtocolLayer.Output) -> Void) {
    protocolLayer.handler = handler
  }
  
  func sendPacket(_ packet: ServerboundPacket) {
    protocolLayer.send(packet)
  }
}
