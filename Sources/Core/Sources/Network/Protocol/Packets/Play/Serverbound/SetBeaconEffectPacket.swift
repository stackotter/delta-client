import Foundation

public struct SetBeaconEffectPacket: ServerboundPacket {
  public static let id: Int = 0x23
  
  public var primaryEffect: Int32
  public var secondaryEffect: Int32
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(primaryEffect)
    writer.writeVarInt(secondaryEffect)
  }
}
