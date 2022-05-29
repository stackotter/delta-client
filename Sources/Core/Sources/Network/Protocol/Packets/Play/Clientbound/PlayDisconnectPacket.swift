import Foundation

public struct PlayDisconnectPacket: ClientboundPacket {
  public static let id: Int = 0x1a
  
  public var reason: ChatComponent
  
  public init(from packetReader: inout PacketReader) throws {
    reason = try packetReader.readChat()
  }
  
  public func handle(for client: Client) {
    let locale = client.resourcePack.getDefaultLocale()
    let message = reason.toText(with: locale)

    log.info("Disconnected from server: \(message)")
    client.eventBus.dispatch(PlayDisconnectEvent(reason: message))
  }
}
