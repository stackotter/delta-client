//
//  ServerPinger.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 20/1/21.
//

import Foundation


class ServerPinger: Hashable, ObservableObject {
  @Published var pingResult: PingResult?
  
  var eventManager: EventManager<ServerEvent>
  var descriptor: ServerDescriptor
  var connection: ServerConnection
  var packetRegistry: PacketRegistry
  
  // Init
  
  init(_ descriptor: ServerDescriptor) {
    self.eventManager = EventManager<ServerEvent>()
    self.descriptor = descriptor
    self.packetRegistry = PacketRegistry.createDefault()
    self.connection = ServerConnection(host: descriptor.host, port: descriptor.port, eventManager: self.eventManager)
    self.connection.setPacketHandler(handlePacket)
  }
  
  // Networking
  
  func ping() {
    pingResult = nil
    eventManager.registerOneTimeEventHandler({ _ in
      self.connection.handshake(nextState: .status)
      
      let statusRequest = StatusRequestPacket()
      self.connection.sendPacket(statusRequest)
    }, eventName: "connectionReady")
    connection.restart()
  }
  
  func handlePacket(_ packetReader: PacketReader) {
    do {
      var reader = packetReader
      if let packetState = connection.state.toPacketState() {
        guard let packetType = packetRegistry.getClientboundPacketType(withId: reader.packetId, andState: packetState) else {
          log.debug("non-existent packet received with id 0x\(String(reader.packetId, radix: 16))")
          return
        }
        let packet = try packetType.init(from: &reader)
        try packet.handle(for: self)
      }
    } catch {
      log.debug("failed to handle packet: \(error)")
    }
  }
  
  // Conformance: Hashable
  
  static func == (lhs: ServerPinger, rhs: ServerPinger) -> Bool {
    return lhs.descriptor == rhs.descriptor
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(descriptor)
  }
}
