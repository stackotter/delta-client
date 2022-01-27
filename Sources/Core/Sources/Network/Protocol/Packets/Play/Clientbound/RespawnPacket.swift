import Foundation

public enum RespawnPacketError: LocalizedError {
  case invalidRawGamemode(Int8)
  case invalidRawPreviousGamemode(Int8)
}

public struct RespawnPacket: ClientboundPacket, WorldDescriptor {
  public static let id: Int = 0x3a
  
  public var dimension: Identifier
  public var worldName: Identifier
  public var hashedSeed: Int
  public var gamemode: Gamemode
  public var previousGamemode: Gamemode?
  public var isDebug: Bool
  public var isFlat: Bool
  public var copyMetadata: Bool

  public init(from packetReader: inout PacketReader) throws {
    dimension = try packetReader.readIdentifier()
    worldName = try packetReader.readIdentifier()
    hashedSeed = packetReader.readLong()
    
    let rawGamemode = packetReader.readByte()
    let rawPreviousGamemode = packetReader.readByte()
    
    guard let gamemode = Gamemode(rawValue: rawGamemode) else {
      throw RespawnPacketError.invalidRawGamemode(rawGamemode)
    }
    
    self.gamemode = gamemode
    
    if rawPreviousGamemode == -1 {
      previousGamemode = nil
    } else {
      guard let previousGamemode = Gamemode(rawValue: rawPreviousGamemode) else {
        throw RespawnPacketError.invalidRawPreviousGamemode(rawPreviousGamemode)
      }
      
      self.previousGamemode = previousGamemode
    }
    
    isDebug = packetReader.readBool()
    isFlat = packetReader.readBool()
    copyMetadata = packetReader.readBool() // TODO: not used yet
  }
  
  public func handle(for client: Client) throws {
    // TODO: check if the discussion at https://wiki.vg/Protocol#Respawn about respawning to the same dimension applies or if it's just a java edition bug
    client.game.setWorld(World(from: self, eventBus: client.eventBus))
    
    client.game.accessPlayer { player in
      player.gamemode.gamemode = gamemode
      player.attributes.previousGamemode = previousGamemode
    }
    
    // TODO: get auto respawn working
    let clientStatus = ClientStatusPacket(action: .performRespawn)
    try client.sendPacket(clientStatus)
  }
}
