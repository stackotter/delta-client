import Foundation

public struct OpenSignEditorPacket: ClientboundPacket {
  public static let id: Int = 0x2f
  
  public var location: Position
  
  public init(from packetReader: inout PacketReader) throws {
    location = packetReader.readPosition()
  }
}
