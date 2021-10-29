import Foundation

public struct EffectPacket: ClientboundPacket {
  public static let id: Int = 0x22
  
  public var effectId: Int
  public var location: Position
  public var data: Int
  public var disableRelativeVolume: Bool
  
  public init(from packetReader: inout PacketReader) throws {
    effectId = packetReader.readInt()
    location = packetReader.readPosition()
    data = packetReader.readInt()
    disableRelativeVolume = packetReader.readBool()
  }
}
