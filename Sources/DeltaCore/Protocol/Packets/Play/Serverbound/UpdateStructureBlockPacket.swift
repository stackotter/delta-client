//
//  UpdateStructureBlockPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct UpdateStructureBlockPacket: ServerboundPacket {
  static let id: Int = 0x29
  
  var location: Position
  var action: StructureBlockAction
  var mode: StructureBlockMode
  var name: String
  var offsetX: Int8
  var offsetY: Int8
  var offsetZ: Int8
  var sizeX: Int8
  var sizeY: Int8
  var sizeZ: Int8
  var mirror: StructureBlockMirror
  var rotation: StructureBlockRotation
  var metadata: String
  var integrity: Float
  var seed: Int64
  var flags: Int8
  
  enum StructureBlockAction: Int32 {
    case updateData = 0
    case saveStructure = 1
    case loadStructure = 2
    case detectSize = 3
  }
  
  enum StructureBlockMode: Int32 {
    case save = 0
    case load = 1
    case corner = 2
    case data = 3
  }
  
  enum StructureBlockMirror: Int32 {
    case none = 0
    case leftRight = 1
    case frontBack = 2
  }
  
  enum StructureBlockRotation: Int32 {
    case none = 0
    case clockwise90 = 1
    case clockwise180 = 2
    case counterClockwise90 = 3
  }
  
  func writePayload(to writer: inout PacketWriter) {
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
