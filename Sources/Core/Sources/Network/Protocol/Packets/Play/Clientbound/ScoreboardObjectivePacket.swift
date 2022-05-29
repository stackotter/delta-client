import Foundation

public struct ScoreboardObjectivePacket: ClientboundPacket {
  public static let id: Int = 0x4a
  
  public var objectiveName: String
  public var mode: UInt8
  public var objectiveValue: ChatComponent?
  public var type: Int?

  public init(from packetReader: inout PacketReader) throws {
    objectiveName = try packetReader.readString()
    mode = try packetReader.readUnsignedByte()
    if mode == 0 || mode == 2 {
      objectiveValue = try packetReader.readChat()
      type = try packetReader.readVarInt()
    }
  }
}
