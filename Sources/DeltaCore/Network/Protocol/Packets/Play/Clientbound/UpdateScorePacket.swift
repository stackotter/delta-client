import Foundation

public struct UpdateScorePacket: ClientboundPacket {
  public static let id: Int = 0x4d
  
  public var entityName: String
  public var action: Int8
  public var objectiveName: String
  public var value: Int?
  
  public init(from packetReader: inout PacketReader) throws {
    // TODO: implement strings with max length in packetreader
    entityName = try packetReader.readString()
    action = packetReader.readByte()
    objectiveName = try packetReader.readString()
    if action != 1 {
      value = packetReader.readVarInt()
    }
  }
}
