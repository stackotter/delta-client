import Foundation

public struct PacketDecodingErrorEvent: Event {
  public var packetId: Int
  public var error: String
}
