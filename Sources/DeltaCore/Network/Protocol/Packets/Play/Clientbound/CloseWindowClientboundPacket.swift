import Foundation

public struct CloseWindowClientboundPacket: ClientboundPacket {
  public static let id: Int = 0x13
  
  public var windowId: UInt8
  
  public init(from packetReader: inout PacketReader) throws {
    windowId = packetReader.readUnsignedByte()
  }
}
