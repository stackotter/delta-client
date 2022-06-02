import Foundation

public struct StopSoundPacket: ClientboundPacket {
  public static let id: Int = 0x52
  
  public var flags: Int8
  public var source: Int?
  public var sound: Identifier?

  public init(from packetReader: inout PacketReader) throws {
    flags = try packetReader.readByte()
    if flags & 0x1 == 0x1 {
      source = try packetReader.readVarInt()
    }
    if flags & 0x2 == 0x2 {
      sound = try packetReader.readIdentifier()
    }
  }
}
