import Foundation

public struct PlayerPositionPacket: ServerboundPacket {
  public static let id: Int = 0x12
  
  public var position: EntityPosition // Feet position
  public var onGround: Bool
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeEntityPosition(position)
    writer.writeBool(onGround)
  }
}
