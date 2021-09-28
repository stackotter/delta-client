//
//  UpdateStructureBlockPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

public struct UpdateStructureBlockPacket: ServerboundPacket {
  public static let id: Int = 0x29
  
  public var location: Position
  public var action: StructureBlockAction
  public var mode: StructureBlockMode
  public var name: String
  public var offsetX: Int8
  public var offsetY: Int8
  public var offsetZ: Int8
  public var sizeX: Int8
  public var sizeY: Int8
  public var sizeZ: Int8
  public var mirror: StructureBlockMirror
  public var rotation: StructureBlockRotation
  public var metadata: String
  public var integrity: Float
  public var seed: Int64
  public var flags: Int8
  
  public enum StructureBlockAction: Int32 {
    case updateData = 0
    case saveStructure = 1
    case loadStructure = 2
    case detectSize = 3
  }
  
  public enum StructureBlockMode: Int32 {
    case save = 0
    case load = 1
    case corner = 2
    case data = 3
  }
  
  public enum StructureBlockMirror: Int32 {
    case none = 0
    case leftRight = 1
    case frontBack = 2
  }
  
  public enum StructureBlockRotation: Int32 {
    case none = 0
    case clockwise90 = 1
    case clockwise180 = 2
    case counterClockwise90 = 3
  }
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writePosition(location)
    writer.writeVarInt(action.rawValue)
    writer.writeVarInt(mode.rawValue)
    writer.writeString(name)
    writer.writeByte(offsetX)
    writer.writeByte(offsetY)
    writer.writeByte(offsetZ)
    writer.writeByte(sizeX)
    writer.writeByte(sizeY)
    writer.writeByte(sizeZ)
    writer.writeVarInt(mirror.rawValue)
    writer.writeVarInt(rotation.rawValue)
    writer.writeString(metadata)
    writer.writeFloat(integrity)
    writer.writeVarLong(seed)
    writer.writeByte(flags)
  }
}
