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
  
  func setPacketHandler(_ handler: @escaping (ProtocolLayer.Output) -> Void) {
    innerMostLayer.handler = handler
  }
  
  func connect() {
    ioLayer.connect()
  }
  
  func disconnect() {
    ioLayer.disconnect()
  }
  
  func restart() {
    disconnect()
    
    let ioLayerSuccessor = ioLayer.inboundSuccessor
    ioLayer = SocketLayer(host, port, thread: thread, eventManager: eventManager)
    ioLayer.inboundSuccessor = ioLayerSuccessor
    
    connect()
  }
  
  func sendPacket(_ packet: ServerboundPacket) {
    innerMostLayer.send(packet)
  }
}
