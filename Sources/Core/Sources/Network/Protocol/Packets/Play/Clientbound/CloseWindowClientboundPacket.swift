import Foundation

public struct CloseWindowClientboundPacket: ClientboundPacket {
  public static let id: Int = 0x13
  
  public var windowId: UInt8
  
  public init(from packetReader: inout PacketReader) throws {
    windowId = try packetReader.readUnsignedByte()
  }

  public func handle(for client: Client) throws {
    client.game.mutateGUIState { guiState in
      guard let window = guiState.window else {
        log.warning("Received CloseWindowClientboundPacket with no open window (window id: \(windowId))")
        return
      }

      guard window.id == windowId else {
        log.warning("Received CloseWindowClientboundPacket for non-existent window with id '\(windowId)'")
        return
      }

      guiState.window = nil

      client.eventBus.dispatch(CaptureCursorEvent())
    }
  }
}
