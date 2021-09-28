//
//  ProtocolLayer.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 31/3/21.
//

import Foundation

public class ProtocolLayer: InnermostNetworkLayer {
  public typealias Packet = ServerboundPacket
  public typealias Output = PacketReader
  
  public var inboundSuccessor: InboundNetworkLayer?
  public var outboundSuccessor: OutboundNetworkLayer?
  
  public var handler: ((PacketReader) -> Void)?
  
  private var outboundThread: DispatchQueue
  
  public init(outboundThread: DispatchQueue) {
    self.outboundThread = outboundThread
  }
  
  public func handleInbound(_ buffer: Buffer) {
    let packetReader = PacketReader(buffer: buffer)
    log.trace("packet received: 0x\(String(format: "%02x", packetReader.packetId))")
    if let callback = handler {
      callback(packetReader)
    }
  }
  
  public func send(_ packet: ServerboundPacket) {
    outboundThread.sync {
      if let nextLayer = self.outboundSuccessor {
        let buffer = packet.toBuffer()
        nextLayer.handleOutbound(buffer)
      }
    }
  }
}
