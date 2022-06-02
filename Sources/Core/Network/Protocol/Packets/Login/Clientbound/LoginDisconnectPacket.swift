import Foundation

public struct LoginDisconnectPacket: ClientboundPacket {
  public static let id: Int = 0x00
  
  public var reason: ChatComponent
  
  public init(from packetReader: inout PacketReader) throws {
    reason = try packetReader.readChat()
  }
  
  public func handle(for client: Client) {
    let locale = client.resourcePack.getDefaultLocale()
    let message = reason.toText(with: locale)

    log.trace("Disconnected from server: \(message)")
    client.eventBus.dispatch(LoginDisconnectEvent(reason: message))
  }
}
