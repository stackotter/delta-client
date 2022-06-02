import Foundation

public struct PlayerDiggingPacket: ServerboundPacket {
  public static let id: Int = 0x1b
  
  public var status: DiggingStatus
  public var location: BlockPosition
  public var face: Direction
  
  public enum DiggingStatus: Int32 {
    case startedDigging = 0
    case cancelledDigging = 1
    case finishedDigging = 2
    case dropItemStack = 3
    case dropItem = 4
    case shootArrowOrFinishEating = 5
    case swapItemInHand = 6
  }
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(status.rawValue)
    writer.writePosition(location)
    writer.writeByte(Int8(face.rawValue))
  }
}
