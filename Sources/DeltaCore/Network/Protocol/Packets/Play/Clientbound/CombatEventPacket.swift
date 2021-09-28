import Foundation

public struct CombatEventPacket: ClientboundPacket {
  public static let id: Int = 0x32
  
  public var event: CombatEvent?
  
  public enum CombatEvent {
    case enterCombat
    case endCombat(duration: Int, entityId: Int)
    case entityDead(playerId: Int, entityId: Int, message: ChatComponent)
  }
  
  public init(from packetReader: inout PacketReader) throws {
    let eventId = packetReader.readVarInt()
    switch eventId {
      case 0: // enter combat
        event = .enterCombat
      case 1: // end combat
        let duration = packetReader.readVarInt()
        let entityId = packetReader.readInt()
        event = .endCombat(duration: duration, entityId: entityId)
      case 2: // entity dead
        let playerId = packetReader.readVarInt()
        let entityId = packetReader.readInt()
        let message = try packetReader.readChat()
        event = .entityDead(playerId: playerId, entityId: entityId, message: message)
      default:
        event = nil
    }
  }
}
