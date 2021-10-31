import Foundation

public struct AdvancementTabPacket: ServerboundPacket {
  public static let id: Int = 0x21
  
  public var action: AdvancementTabAction
  
  public enum AdvancementTabAction {
    case openedTab(tabId: Identifier)
    case closedScreen
  }
  
  public func writePayload(to writer: inout PacketWriter) {
    switch action {
      case let .openedTab(tabId: tabId):
        writer.writeVarInt(0) // opened tab
        writer.writeIdentifier(tabId)
      case .closedScreen:
        writer.writeVarInt(1) // closed screen
    }
  }
}
