import Foundation

public struct UpdateHealthPacket: ClientboundPacket {
  public static let id: Int = 0x49
  
  public var health: Float
  public var food: Int
  public var foodSaturation: Float

  public init(from packetReader: inout PacketReader) throws {
    health = try packetReader.readFloat()
    food = try packetReader.readVarInt() 
    foodSaturation = try packetReader.readFloat()
  }
  
  public func handle(for client: Client) throws {
    client.game.accessPlayer { player in
      player.health.health = health
      player.nutrition.food = food
      player.nutrition.saturation = foodSaturation
    }
    
    if health <= 0 {
      // TODO: Handle death
      log.debug("Died")
    }
  }
}
