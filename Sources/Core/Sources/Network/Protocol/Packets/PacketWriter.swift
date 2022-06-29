import Foundation
import simd

// TODO: document packet writer
public struct PacketWriter {
  public var buffer = Buffer([])

  // MARK: Basic datatypes

  public mutating func writeBool(_ bool: Bool) {
    let byte: UInt8 = bool ? 1 : 0
    writeUnsignedByte(byte)
  }

  public mutating func writeByte(_ byte: Int8) {
    buffer.writeSignedByte(byte)
  }

  public  mutating func writeUnsignedByte(_ unsignedByte: UInt8) {
    buffer.writeByte(unsignedByte)
  }

  public mutating func writeByteArray(_ byteArray: [UInt8]) {
    buffer.writeBytes(byteArray)
  }

  public mutating func writeShort(_ short: Int16) {
    buffer.writeSignedShort(short, endianness: .big)
  }

  public mutating func writeUnsignedShort(_ unsignedShort: UInt16) {
    buffer.writeShort(unsignedShort, endianness: .big)
  }

  public mutating func writeInt(_ int: Int32) {
    buffer.writeSignedInt(int, endianness: .big)
  }

  public mutating func writeLong(_ long: Int64) {
    buffer.writeSignedLong(long, endianness: .big)
  }

  public mutating func writeFloat(_ float: Float) {
    buffer.writeFloat(float, endianness: .big)
  }

  public mutating func writeDouble(_ double: Double) {
    buffer.writeDouble(double, endianness: .big)
  }

  public mutating func writeString(_ string: String) {
    let length = string.utf8.count
    precondition(length < 32767, "string too long to write")

    writeVarInt(Int32(length))
    buffer.writeString(string)
  }

  public mutating func writeVarInt(_ varInt: Int32) {
    buffer.writeVarInt(varInt)
  }

  public mutating func writeVarLong(_ varLong: Int64) {
    buffer.writeVarLong(varLong)
  }

  public mutating func writeIdentifier(_ identifier: Identifier) {
    writeString(identifier.description)
  }

  // MARK: Complex datatypes
  // IMPLEMENT: Entity Metadata, Angle

  public mutating func writeItemStack(_ itemStack: ItemStack) {
    writeBool(itemStack.isEmpty)
    if !itemStack.isEmpty {
      // TODO: use enum for itemstack
      if let itemId = itemStack.itemId {
        let nbt = itemStack.itemNBT ?? NBT.Compound()
        writeVarInt(Int32(itemId))
        writeByte(Int8(itemStack.count))
        writeNBT(nbt)
      }
    }
  }

  public mutating func writeNBT(_ nbtCompound: NBT.Compound) {
    var compound = nbtCompound
    buffer.writeBytes(compound.pack())
  }

  public mutating func writeUUID(_ uuid: UUID) {
    let bytes = uuid.toBytes()
    buffer.writeBytes(bytes)
  }

  public mutating func writePosition(_ position: BlockPosition) {
    var val: UInt64 = (UInt64(position.x) & 0x3FFFFFF) << 38
    val |= (UInt64(position.z) & 0x3FFFFFF) << 12
    val |= UInt64(position.y) & 0xFFF
    buffer.writeLong(val, endianness: .big)
  }

  public mutating func writeEntityPosition(_ position: SIMD3<Double>) {
    writeDouble(position.x)
    writeDouble(position.y)
    writeDouble(position.z)
  }
}
