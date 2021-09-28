//
//  BlockEntityDataPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

public struct BlockEntityDataPacket: ClientboundPacket {
  public static let id: Int = 0x09
  
  public var location: Position
  public var action: UInt8
  public var nbtData: NBT.Compound
  
  public init(from packetReader: inout PacketReader) throws {
    location = packetReader.readPosition()
    action = packetReader.readUnsignedByte()
    nbtData = try packetReader.readNBTCompound()
  }
}
