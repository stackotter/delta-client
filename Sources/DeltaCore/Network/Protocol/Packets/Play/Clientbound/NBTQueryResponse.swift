import Foundation

public struct NBTQueryResponse: ClientboundPacket {
  public static let id: Int = 0x54
  
  public var transactionId: Int
  public var nbt: NBT.Compound

  public init(from packetReader: inout PacketReader) throws {
    transactionId = packetReader.readVarInt()
    nbt = try packetReader.readNBTCompound()
  }
}
