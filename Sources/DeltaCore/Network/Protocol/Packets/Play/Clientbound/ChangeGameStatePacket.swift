import Foundation

public struct ChangeGameStatePacket: ClientboundPacket {
  public static let id: Int = 0x1e
  
  public var reason: UInt8
  public var value: Float
  
  public init(from packetReader: inout PacketReader) throws {
    reason = packetReader.readUnsignedByte()
    value = packetReader.readFloat()
  }
}
