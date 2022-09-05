import Foundation

public struct ChatMessageClientboundPacket: ClientboundEntityPacket {
  public static let id: Int = 0x0e

  public var content: ChatComponent
  public var position: Int8
  public var sender: UUID

  public init(from packetReader: inout PacketReader) throws {
    content = try packetReader.readChat()
    position = try packetReader.readByte()
    sender = try packetReader.readUUID()
  }

  public func handle(for client: Client) throws {
    let locale = client.resourcePack.getDefaultLocale()

    client.game.mutateGUIState(acquireLock: false) { guiState in
      let message = ChatMessage(content: content, sender: sender)
      guiState.chat.add(message)
    }

    let message = content.toText(with: locale)
    log.info(message)
  }
}
