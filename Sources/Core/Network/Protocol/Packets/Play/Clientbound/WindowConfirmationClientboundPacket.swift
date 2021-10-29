import Foundation

public struct WindowConfirmationClientboundPacket: ClientboundPacket {
  public static let id: Int = 0x12
  
  public var windowId: Int8
  public var actionNumber: Int16
  public var accepted: Bool
  
  public init(from packetReader: inout PacketReader) throws {
    windowId = packetReader.readByte()
    actionNumber = packetReader.readShort()
    accepted = packetReader.readBool()
  }
}
