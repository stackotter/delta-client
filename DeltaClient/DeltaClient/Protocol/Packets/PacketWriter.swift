//
//  PacketWriter.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 12/12/20.
//

import Foundation

struct PacketWriter {
  var buf: Buffer = Buffer([])
  
  init() {
    
  }
  
  mutating func pack() -> [UInt8] {
    let temp = buf
    let length = buf.length
    buf = Buffer()
    writeVarInt(Int32(length))
    buf.writeBytes(temp.byteBuf)
    return buf.byteBuf
  }
  
  mutating func writeBool(_ bool: Bool) {
    let byte: UInt8 = bool ? 1 : 0
    writeUnsignedByte(byte)
  }
  
  mutating func writeByte(_ byte: Int8) {
    buf.writeSignedByte(byte)
  }
  
  mutating func writeUnsignedByte(_ unsignedByte: UInt8) {
    buf.writeByte(unsignedByte)
  }
  
  mutating func writeShort(_ short: Int16) {
    buf.writeSignedShort(short, endian: .big)
  }
  
  mutating func writeUnsignedShort(_ unsignedShort: UInt16) {
    buf.writeShort(unsignedShort, endian: .big)
  }
  
  mutating func writeInt(_ int: Int32) {
    buf.writeSignedInt(int, endian: .big)
  }
  
  mutating func writeLong(_ long: Int64) {
    buf.writeSignedLong(long, endian: .big)
  }
  
  mutating func writeFloat(_ float: Float) {
    buf.writeFloat(float, endian: .big)
  }
  
  mutating func writeDouble(_ double: Double) {
    buf.writeDouble(double, endian: .big)
  }
  
  mutating func writeString(_ string: String) {
    let length = string.utf8.count
    precondition(length < 32767, "string too long to write")
    
    writeVarInt(Int32(length))
    buf.writeString(string)
  }
  
  mutating func writeIdentifier(_ identifier: Identifier) {
    writeString(identifier.toString())
  }
  
  mutating func writeVarInt(_ varInt: Int32) {
    buf.writeVarInt(varInt)
  }
  
  mutating func writeVarLong(_ varLong: Int64) {
    buf.writeVarLong(varLong)
  }
  
  // IMPLEMENT: Entity Metadata, Position, Angle
  
  mutating func writeItemStack(_ itemStack: ItemStack) {
    writeBool(itemStack.isEmpty)
    if itemStack.isEmpty {
      let item = itemStack.item!
      writeVarInt(Int32(item.id))
      writeByte(Int8(itemStack.count))
      writeNBT(item.nbt ?? NBTCompound())
    }
  }
  
  mutating func writeNBT(_ nbtCompound: NBTCompound) {
    var compound = nbtCompound
    buf.writeBytes(compound.pack())
  }
  
  mutating func writeUUID(_ uuid: UUID) {
    let bytes = uuid.toBytes()
    buf.writeBytes(bytes)
  }
  
  mutating func writeByteArray(_ byteArray: [UInt8]) {
    buf.writeBytes(byteArray)
  }
  
  mutating func writePosition(_ position: Position) {
    var val: UInt64 = (UInt64(position.x) & 0x3FFFFFF) << 38
    val |= (UInt64(position.z) & 0x3FFFFFF) << 12
    val |= UInt64(position.y) & 0xFFF
    buf.writeLong(val, endian: .big)
  }
  
  mutating func writeEntityPosition(_ entityPosition: EntityPosition) {
    writeDouble(entityPosition.x)
    writeDouble(entityPosition.y)
    writeDouble(entityPosition.z)
  }
}
