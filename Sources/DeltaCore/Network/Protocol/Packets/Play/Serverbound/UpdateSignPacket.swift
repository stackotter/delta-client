import Foundation

public struct UpdateSignPacket: ServerboundPacket {
  public static let id: Int = 0x2a
  
  public var location: Position
  public var line1: String
  public var line2: String
  public var line3: String
  public var line4: String
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writePosition(location)
    writer.writeString(line1)
    writer.writeString(line2)
    writer.writeString(line3)
    writer.writeString(line4)
  }
}
