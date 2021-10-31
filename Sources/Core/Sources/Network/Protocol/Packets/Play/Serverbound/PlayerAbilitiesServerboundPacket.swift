import Foundation

public struct PlayerAbilitiesServerboundPacket: ServerboundPacket {
  public static let id: Int = 0x1a
  
  public var flags: PlayerFlags
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeUnsignedByte(flags.rawValue)
  }
}
