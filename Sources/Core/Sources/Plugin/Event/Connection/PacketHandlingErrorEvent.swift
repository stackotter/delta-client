import Foundation

public struct PacketHandlingErrorEvent: Event {
  public var packetId: Int
  public var error: String
}
