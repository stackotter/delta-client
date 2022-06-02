import Foundation

public struct EffectPacket: ClientboundPacket {
  public static let id: Int = 0x22
  
  public var effectId: Int
  public var location: BlockPosition
  public var data: Int
  public var disableRelativeVolume: Bool
  
  public init(from packetReader: inout PacketReader) throws {
    effectId = try packetReader.readInt()
    location = try packetReader.readBlockPosition()
    data = try packetReader.readInt()
    disableRelativeVolume = try packetReader.readBool()
  }
}
