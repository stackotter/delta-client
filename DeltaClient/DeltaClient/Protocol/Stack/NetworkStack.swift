//
//  NetworkStack.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 31/3/21.
//

import Foundation

class NetworkStack {
  var thread: DispatchQueue
  var eventManager: EventManager
  
  var host: String
  var port: UInt16
  
  // network layers
  var socketLayer: SocketLayer
  var packetLayer: PacketLayer
  var compressionLayer: CompressionLayer
  var protocolLayer: ProtocolLayer
  
  // Init
  
  init(_ host: String, _ port: UInt16, eventManager: EventManager) {
    self.host = host
    self.port = port
    
    self.eventManager = eventManager
    self.thread = DispatchQueue(label: "networkingStack")
    
    // create layers
    socketLayer = SocketLayer(host, port, thread: self.thread, eventManager: self.eventManager)
    packetLayer = PacketLayer()
    compressionLayer = CompressionLayer()
    protocolLayer = ProtocolLayer(thread: self.thread)
    
    // setup inbound flow
    socketLayer.inboundSuccessor = packetLayer
    packetLayer.inboundSuccessor = compressionLayer
    compressionLayer.inboundSuccessor = protocolLayer
    
    // setup outbound flow
    protocolLayer.outboundSuccessor = compressionLayer
    compressionLayer.outboundSuccessor = packetLayer
    packetLayer.outboundSuccessor = socketLayer
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
    socketLayer = SocketLayer(host, port, thread: thread, eventManager: eventManager)
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
