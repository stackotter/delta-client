import Foundation

public struct OpenWindowPacket: ClientboundPacket {
  public static let id: Int = 0x2e
  
  public var windowId: Int
  public var windowType: Int
  public var windowTitle: ChatComponent
  
  public init(from packetReader: inout PacketReader) throws {
    windowId = try packetReader.readVarInt()
    windowType = try packetReader.readVarInt()
    windowTitle = try packetReader.readChat()
  }
}
