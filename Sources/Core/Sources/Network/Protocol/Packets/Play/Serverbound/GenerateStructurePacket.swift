import Foundation

public struct GenerateStructurePacket: ServerboundPacket {
  public static let id: Int = 0x0f
  
  public var location: Position
  public var levels: Int32
  public var keepJigsaws: Bool
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writePosition(location)
    writer.writeVarInt(levels)
    writer.writeBool(keepJigsaws)
  }
}
