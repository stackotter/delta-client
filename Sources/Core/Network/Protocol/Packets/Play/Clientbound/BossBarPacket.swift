import Foundation

public struct BossBarPacket: ClientboundPacket {
  public static let id: Int = 0x0c
  
  public var uuid: UUID
  public var action: BossBarAction
  
  public enum BossBarAction {
    case add(title: ChatComponent, health: Float, color: Int, division: Int, flags: UInt8)
    case remove
    case updateHealth(health: Float)
    case updateTitle(title: ChatComponent)
    case updateStyle(color: Int, division: Int)
    case updateFlags(flags: UInt8)
  }
  
  public init(from packetReader: inout PacketReader) throws {
    uuid = try packetReader.readUUID()
    let actionId = try packetReader.readVarInt()
    
    switch actionId {
      case 0:
        let title = try packetReader.readChat()
        let health = try packetReader.readFloat()
        let color = try packetReader.readVarInt()
        let division = try packetReader.readVarInt()
        let flags = try packetReader.readUnsignedByte()
        action = .add(title: title, health: health, color: color, division: division, flags: flags)
      case 1:
        action = .remove
      case 2:
        let health = try packetReader.readFloat()
        action = .updateHealth(health: health)
      case 3:
        let title = try packetReader.readChat()
        action = .updateTitle(title: title)
      case 4:
        let color = try packetReader.readVarInt()
        let division = try packetReader.readVarInt()
        action = .updateStyle(color: color, division: division)
      case 5:
        let flags = try packetReader.readUnsignedByte()
        action = .updateFlags(flags: flags)
      default:
        log.warning("invalid boss bar action id")
        action = .remove
    }
  }
}
