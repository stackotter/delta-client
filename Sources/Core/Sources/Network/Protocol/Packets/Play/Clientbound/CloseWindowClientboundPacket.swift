import Foundation

public struct CloseWindowClientboundPacket: ClientboundPacket {
  public static let id: Int = 0x13
  
  public var windowId: UInt8
  
  public init(from packetReader: inout PacketReader) throws {
    windowId = try packetReader.readUnsignedByte()
  }

  public func handle(for client: Client) throws {
    try client.game.mutateGUIState { guiState in
      guard let window = guiState.window else {
        log.warning("Received CloseWindowClientboundPacket with no open window (window id: \(windowId))")
        return
      }

      guard window.id == windowId else {
        log.warning("Received CloseWindowClientboundPacket for non-existent window with id '\(windowId)'")
        return
      }

      // Connection is set to nil since we don't need to send a packet (we just received one)
      try window.close(mouseStack: &guiState.mouseItemStack, eventBus: client.eventBus, connection: nil)
    }
  }
}
