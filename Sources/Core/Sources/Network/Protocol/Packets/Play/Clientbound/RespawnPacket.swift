import Foundation

public enum RespawnPacketError: LocalizedError {
  case invalidGamemodeRawValue(Int8)
  case invalidPreviousGamemodeRawValue(Int8)
  
  public var errorDescription: String? {
    switch self {
      case .invalidGamemodeRawValue(let rawValue):
        return """
        Invalid gamemode raw value.
        Raw value: \(rawValue)
        """
      case .invalidPreviousGamemodeRawValue(let rawValue):
        return """
        Invalid previous gamemode raw value.
        Raw value: \(rawValue)
        """
    }
  }
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
    hashedSeed = try packetReader.readLong()
    
    let rawGamemode = try packetReader.readByte()
    let rawPreviousGamemode = try packetReader.readByte()
    
    guard let gamemode = Gamemode(rawValue: rawGamemode) else {
      throw RespawnPacketError.invalidGamemodeRawValue(rawGamemode)
    }
    
    self.gamemode = gamemode
    
    if rawPreviousGamemode == -1 {
      previousGamemode = nil
    } else {
      guard let previousGamemode = Gamemode(rawValue: rawPreviousGamemode) else {
        throw RespawnPacketError.invalidPreviousGamemodeRawValue(rawPreviousGamemode)
      }
      
      self.previousGamemode = previousGamemode
    }
    
    isDebug = try packetReader.readBool()
    isFlat = try packetReader.readBool()
    copyMetadata = try packetReader.readBool() // TODO: not used yet
  }
  
  public func handle(for client: Client) throws {
    // TODO: check if the discussion at https://wiki.vg/Protocol#Respawn about respawning to the same dimension applies or if it's just a java edition bug
    client.game.changeWorld(to: World(from: self, eventBus: client.eventBus))
    
    client.game.accessPlayer { player in
      player.gamemode.gamemode = gamemode
      player.playerAttributes.previousGamemode = previousGamemode
    }
    
    // TODO: get auto respawn working
    let clientStatus = ClientStatusPacket(action: .performRespawn)
    try client.sendPacket(clientStatus)
  }
}
