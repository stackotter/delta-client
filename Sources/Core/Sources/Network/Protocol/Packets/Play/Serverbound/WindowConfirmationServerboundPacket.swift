import Foundation

public struct WindowConfirmationServerboundPacket: ServerboundPacket {
  public static let id: Int = 0x07
  
  public var windowId: Int8
  public var actionNumber: Int16
  public var accepted: Bool
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeByte(windowId)
    writer.writeShort(actionNumber)
    writer.writeBool(accepted)
  }
}
