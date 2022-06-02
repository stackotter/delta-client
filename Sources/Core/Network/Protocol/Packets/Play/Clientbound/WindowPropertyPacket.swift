import Foundation

public struct WindowPropertyPacket: ClientboundPacket {
  public static let id: Int = 0x15
  
  public var windowId: UInt8
  public var property: Int16
  public var value: Int16
  
  public init(from packetReader: inout PacketReader) throws {
    windowId = try packetReader.readUnsignedByte()
    property = try packetReader.readShort()
    value = try packetReader.readShort()
  }
}
