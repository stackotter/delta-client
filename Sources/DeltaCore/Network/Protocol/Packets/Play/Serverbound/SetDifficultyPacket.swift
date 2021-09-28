import Foundation

public struct SetDifficultyPacket: ServerboundPacket {
  public static let id: Int = 0x02
  
  public var newDifficulty: Difficulty
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeUnsignedByte(newDifficulty.rawValue)
  }
}
