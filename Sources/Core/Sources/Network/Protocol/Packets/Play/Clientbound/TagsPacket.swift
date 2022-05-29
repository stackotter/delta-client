import Foundation

// TODO_LATER: fill this out more as needed
public struct TagsPacket: ClientboundPacket {
  public static let id: Int = 0x5b
  
  public init(from packetReader: inout PacketReader) throws {
    for _ in 0..<4 {
      let length = try packetReader.readVarInt()
      for _ in 0..<length {
        let tagName = try packetReader.readString()
        _ = tagName
        let count = try packetReader.readVarInt()
        for _ in 0..<count {
          let entry = try packetReader.readVarInt()
          _ = entry
        }
      }
    }
  }
}
