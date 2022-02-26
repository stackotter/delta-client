import Foundation

public struct PlayerAbilitiesPacket: ClientboundPacket {
  public static let id: Int = 0x31
  
  public var flags: PlayerFlags
  public var flyingSpeed: Float
  public var fovModifier: Float
  
  public init(from packetReader: inout PacketReader) {
    flags = PlayerFlags(rawValue: packetReader.readUnsignedByte())
    flyingSpeed = packetReader.readFloat()
    fovModifier = packetReader.readFloat()
  }
  
  public func handle(for client: Client) throws {
    client.game.accessPlayer { player in
      let attributes = player.playerAttributes
      attributes.flyingSpeed = flyingSpeed
      attributes.fovModifier = fovModifier
      attributes.isInvulnerable = flags.contains(.invulnerable)
      attributes.canFly = flags.contains(.canFly)
      attributes.canInstantBreak = flags.contains(.instantBreak)
      
      player.flying.isFlying = flags.contains(.flying)
    }
  }
}
