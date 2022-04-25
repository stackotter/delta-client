import Foundation

public struct PlayDisconnectPacket: ClientboundPacket {
  public static let id: Int = 0x1a
  
  public var reason: ChatComponent
  
  public init(from packetReader: inout PacketReader) throws {
    reason = try packetReader.readChat()
  }
  
  public func handle(for client: Client) {
    log.trace("Disconnected from server: \(reason.toText())")
    client.eventBus.dispatch(PlayDisconnectEvent(reason: reason.toText()))
  }
}
