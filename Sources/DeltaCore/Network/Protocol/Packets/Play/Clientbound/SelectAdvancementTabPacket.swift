import Foundation

public struct SelectAdvancementTabPacket: ClientboundPacket {
  public static let id: Int = 0x3c
  
  public var identifier: Identifier?

  public init(from packetReader: inout PacketReader) throws {
    if packetReader.readBool() {
      identifier = try packetReader.readIdentifier()
    }
  }
}
