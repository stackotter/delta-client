import Foundation

public struct OpenHorseWindowPacket: ClientboundPacket {
  public static let id: Int = 0x1f
  
  public var windowId: Int8
  public var numberOfSlots: Int
  public var entityId: Int
  
  public init(from packetReader: inout PacketReader) throws {
    windowId = try packetReader.readByte()
    numberOfSlots = try packetReader.readVarInt()
    entityId = try packetReader.readInt()
  }
}
