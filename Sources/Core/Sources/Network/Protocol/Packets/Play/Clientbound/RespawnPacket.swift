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

public struct RespawnPacket: ClientboundPacket {
  public static let id: Int = 0x3a
  
  public var currentDimensionIdentifier: Identifier
  public var worldName: Identifier
  public var hashedSeed: Int
  public var gamemode: Gamemode
  public var previousGamemode: Gamemode?
  public var isDebug: Bool
  public var isFlat: Bool
  public var copyMetadata: Bool

  public init(from packetReader: inout PacketReader) throws {
    currentDimensionIdentifier = try packetReader.readIdentifier()
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
    guard let currentDimension = client.game.dimensions.first(where: { dimension in
      return dimension.identifier == currentDimensionIdentifier
    }) else {
      throw ClientboundPacketError.invalidDimension(currentDimensionIdentifier)
    }

    let world = World(
      name: worldName,
      dimension: currentDimension,
      hashedSeed: hashedSeed,
      isFlat: isFlat,
      isDebug: isDebug,
      eventBus: client.eventBus
    )
  
    // TODO: implement copyMetadata

    // TODO: check if the discussion at https://wiki.vg/Protocol#Respawn about respawning to the same dimension applies or if it's just a java edition bug
    client.game.changeWorld(to: world)

    client.game.accessPlayer { player in
      player.gamemode.gamemode = gamemode
      player.playerAttributes.previousGamemode = previousGamemode
    }
    
    // TODO: get auto respawn working
    let clientStatus = ClientStatusPacket(action: .performRespawn)
    try client.sendPacket(clientStatus)
  }
}
