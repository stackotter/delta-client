import Foundation

public struct AnimationServerboundPacket: ServerboundPacket {
  public static let id: Int = 0x2b
  
  public var hand: Hand
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(hand.rawValue)
  }
}
