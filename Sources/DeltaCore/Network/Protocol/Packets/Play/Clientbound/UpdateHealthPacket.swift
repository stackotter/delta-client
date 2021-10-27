import Foundation

public struct UpdateHealthPacket: ClientboundPacket {
  public static let id: Int = 0x49
  
  public var health: Float
  public var food: Int
  public var foodSaturation: Float

  public init(from packetReader: inout PacketReader) throws {
    health = packetReader.readFloat()
    food = packetReader.readVarInt() 
    foodSaturation = packetReader.readFloat()
  }
  
  public func handle(for client: Client) throws {
    client.game.player.health.health = health
    client.game.player.nutrition.food = food
    client.game.player.nutrition.saturation = foodSaturation
    
    if health <= 0 {
      // TODO: Handle death
      log.debug("Died")
    }
  }
}
