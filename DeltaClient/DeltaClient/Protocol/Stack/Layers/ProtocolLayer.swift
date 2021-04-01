//
//  ProtocolLayer.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 31/3/21.
//

import Foundation
import os

class ProtocolLayer: InnermostNetworkLayer {
  typealias Packet = ServerboundPacket
  typealias Output = PacketReader
  
  var inboundSuccessor: InboundNetworkLayer? = nil
  var outboundSuccessor: OutboundNetworkLayer?
  
  var handler: ((PacketReader) -> Void)?
  var thread: DispatchQueue
  
  init(thread: DispatchQueue) {
    self.thread = thread
  }
  
  func handleInbound(_ buffer: Buffer) {
    let packetReader = PacketReader(buffer: buffer)
    if let callback = handler {
      callback(packetReader)
    }
  }
  
  func send(_ packet: ServerboundPacket) {
    if let nextLayer = outboundSuccessor {
      let buffer = packet.toBuffer()
      nextLayer.handleOutbound(buffer)
    }
  }
}
