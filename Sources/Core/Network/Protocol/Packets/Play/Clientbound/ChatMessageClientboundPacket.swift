import Foundation

public struct ChatMessageClientboundPacket: ClientboundPacket {
  public static let id: Int = 0x0e
  
  public var message: ChatComponent
  public var position: Int8
  public var sender: UUID
  
  public init(from packetReader: inout PacketReader) throws {
    message = try packetReader.readChat()
    position = try packetReader.readByte()
    sender = try packetReader.readUUID()
  }
  
  public func handle(for client: Client) throws {
    let locale = client.resourcePack.getDefaultLocale()
    let message = message.toText(with: locale)

    log.info("Chat message received: \(message)")
  }
}
