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

    let message = ChatMessage(content: content, sender: sender)
    client.game.mutateGUIState(acquireLock: false) { guiState in
      guiState.chat.add(message)
    }

    client.eventBus.dispatch(ChatMessageReceivedEvent(message))

    let text = content.toText(with: locale)
    log.info(text)
  }
}
