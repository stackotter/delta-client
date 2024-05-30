import Foundation

public struct InteractEntityPacket: ServerboundPacket {
  public static let id: Int = 0x0e
  
  public var entityId: Int32
  public var interaction: EntityInteraction
  
  public enum EntityInteraction {
    case interact(hand: Hand, isSneaking: Bool)
    case attack(isSneaking: Bool)
    case interactAt(targetX: Float, targetY: Float, targetZ: Float, hand: Hand, isSneaking: Bool)
  }
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(entityId)
    switch interaction {
      case let .interact(hand: hand, isSneaking: isSneaking):
        writer.writeVarInt(0) // interact
        writer.writeVarInt(hand.rawValue)
        writer.writeBool(isSneaking)
      case let .attack(isSneaking: isSneaking):
        writer.writeVarInt(1) // attack
        writer.writeBool(isSneaking)
      case let .interactAt(targetX: targetX, targetY: targetY, targetZ: targetZ, hand: hand, isSneaking: isSneaking):
        writer.writeVarInt(2) // interact at
        writer.writeFloat(targetX)
        writer.writeFloat(targetY)
        writer.writeFloat(targetZ)
        writer.writeVarInt(hand.rawValue)
        writer.writeBool(isSneaking)
    }
  }
}
