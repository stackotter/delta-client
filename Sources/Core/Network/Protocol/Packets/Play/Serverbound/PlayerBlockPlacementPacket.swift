import Foundation

public struct PlayerBlockPlacementPacket: ServerboundPacket {
  public static let id: Int = 0x2d
  
  public var hand: Hand
  public var location: Position
  public var face: Direction
  public var cursorPositionX: Float
  public var cursorPositionY: Float
  public var cursorPositionZ: Float
  public var insideBlock: Bool
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(hand.rawValue)
    writer.writePosition(location)
    writer.writeVarInt(Int32(face.rawValue)) // wth mojang, why is it a varInt here and a byte somewhere else. it's literally the same enum! >:(
    writer.writeFloat(cursorPositionX)
    writer.writeFloat(cursorPositionY)
    writer.writeFloat(cursorPositionZ)
    writer.writeBool(insideBlock)
  }
}
