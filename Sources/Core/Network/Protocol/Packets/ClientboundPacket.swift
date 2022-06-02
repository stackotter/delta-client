import Foundation

public enum ClientboundPacketError: LocalizedError {
  case invalidDifficulty
  case invalidGamemode
  case invalidServerId
  case invalidJSONString
  case disconnect(reason: String)
}

public protocol ClientboundPacket {
  static var id: Int { get }
  
  init(from packetReader: inout PacketReader) throws
  func handle(for client: Client) throws
  func handle(for pinger: Pinger) throws
}

extension ClientboundPacket {
  public func handle(for client: Client) {
    return
  }
  
  public func handle(for pinger: Pinger) {
    return
  }
}
