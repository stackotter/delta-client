//
//  SpawnPositionPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

public struct SpawnPositionPacket: ClientboundPacket {
  public static let id: Int = 0x42
  
  public var location: Position

  public init(from packetReader: inout PacketReader) throws {
    location = packetReader.readPosition()
  }
  
  public func handle(for client: Client) throws {
    client.server?.player.update(with: self)
    
    log.info("Finished downloading terrain")
    client.eventBus.dispatch(TerrainDownloadCompletionEvent())
    
    // notify server that we are ready to finish login
    let clientStatus = ClientStatusPacket(action: .performRespawn)
    client.sendPacket(clientStatus)
  }
}
