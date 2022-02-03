import Foundation

public struct PlayerMovementPacket: ServerboundPacket {
  public static let id: Int = 0x15
  
  public var onGround: Bool
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeBool(onGround)
  }
}
