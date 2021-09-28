import Foundation

public struct CloseWindowServerboundPacket: ServerboundPacket {
  public static let id: Int = 0x0a
  
  public var windowId: UInt8
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeUnsignedByte(windowId)
  }
}
