import Foundation

public struct BlockEntityDataPacket: ClientboundPacket {
  public static let id: Int = 0x09

  public var position: BlockPosition
  public var action: UInt8
  public var nbtData: NBT.Compound

  public init(from packetReader: inout PacketReader) throws {
    position = try packetReader.readBlockPosition()
    action = try packetReader.readUnsignedByte()
    nbtData = try packetReader.readNBTCompound()
  }
}
