import Foundation

public struct WindowConfirmationClientboundPacket: ClientboundPacket {
  public static let id: Int = 0x12
  
  public var windowId: Int8
  public var actionNumber: Int16
  public var accepted: Bool
  
  public init(from packetReader: inout PacketReader) throws {
    windowId = try packetReader.readByte()
    actionNumber = try packetReader.readShort()
    accepted = try packetReader.readBool()
  }

  public func handle(for client: Client) throws {
    try client.sendPacket(WindowConfirmationServerboundPacket(
      windowId: windowId,
      actionNumber: actionNumber,
      accepted: true
    ))
  }
}
