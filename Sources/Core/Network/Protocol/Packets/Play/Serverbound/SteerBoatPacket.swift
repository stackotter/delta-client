import Foundation

public struct SteerBoatPacket: ServerboundPacket {
  public static let id: Int = 0x17
  
  public var isLeftPaddleTurning: Bool
  public var isRightPaddleTurning: Bool
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeBool(isLeftPaddleTurning)
    writer.writeBool(isRightPaddleTurning)
  }
}
