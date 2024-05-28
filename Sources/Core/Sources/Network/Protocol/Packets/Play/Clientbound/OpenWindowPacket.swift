import Foundation

public struct OpenWindowPacket: ClientboundPacket {
  public static let id: Int = 0x2e
  
  public var windowId: Int
  public var windowTypeId: Int
  public var windowTitle: ChatComponent
  
  public init(from packetReader: inout PacketReader) throws {
    windowId = try packetReader.readVarInt()
    windowTypeId = try packetReader.readVarInt()
    windowTitle = try packetReader.readChat()
  }

  public func handle(for client: Client) throws {
    guard let windowType = WindowType.types[.vanilla(windowTypeId)] else {
      log.warning("Unknown window type '\(windowTypeId)' received in OpenWindowPacket")
      // Immediately close window to avoid accidentally getting banned for starting to
      // move with the window still open.
      try client.connection?.sendPacket(CloseWindowServerboundPacket(
        windowId: UInt8(windowId)
      ))
      return
    }

    client.game.mutateGUIState { guiState in
      guiState.window = Window(
        id: windowId,
        type: windowType
      )
    }

    client.game.accessInputState { inputState in
      inputState.releaseAll()
    }
    client.eventBus.dispatch(ReleaseCursorEvent())
  }
}
