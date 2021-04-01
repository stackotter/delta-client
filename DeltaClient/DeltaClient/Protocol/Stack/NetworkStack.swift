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
  
  var ioLayer: SocketLayer
  var innerMostLayer: ProtocolLayer
  
  // Init
  
  init(_ host: String, _ port: UInt16, eventManager: EventManager) {
    self.host = host
    self.port = port
    
    self.eventManager = eventManager
    self.thread = DispatchQueue(label: "networkingStack")
    
    let socketLayer = SocketLayer(host, port, thread: self.thread, eventManager: self.eventManager)
    let packetLayer = PacketLayer()
    let protocolLayer = ProtocolLayer(thread: self.thread)
    
    socketLayer.inboundSuccessor = packetLayer
    packetLayer.inboundSuccessor = protocolLayer
    
    protocolLayer.outboundSuccessor = packetLayer
    packetLayer.outboundSuccessor = socketLayer
    
    self.ioLayer = socketLayer
    self.innerMostLayer = protocolLayer
  }
  
  // Lifecycle
  
  func connect() {
    ioLayer.connect()
  }
  
  func disconnect() {
    ioLayer.disconnect()
  }
  
  func reconnect() {
    disconnect()
    
    // remake socket layer
    let ioLayerSuccessor = ioLayer.inboundSuccessor
    ioLayer = SocketLayer(host, port, thread: thread, eventManager: eventManager)
    ioLayer.inboundSuccessor = ioLayerSuccessor
    if var outboundPredecessor = ioLayer.inboundSuccessor as? OutboundNetworkLayer {
      outboundPredecessor.outboundSuccessor = ioLayer
    }
    
    connect()
  }
  
  // Packet
  
  func setPacketHandler(_ handler: @escaping (ProtocolLayer.Output) -> Void) {
    innerMostLayer.handler = handler
  }
  
  func sendPacket(_ packet: ServerboundPacket) {
    innerMostLayer.send(packet)
  }
}
