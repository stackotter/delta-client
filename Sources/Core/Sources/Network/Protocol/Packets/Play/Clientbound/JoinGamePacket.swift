import Foundation

public struct JoinGamePacket: ClientboundPacket {
  public static let id: Int = 0x25

  public var playerEntityId: Int
  public var isHardcore: Bool
  public var gamemode: Gamemode
  public var previousGamemode: Gamemode?
  public var worldCount: Int
  public var worldNames: [Identifier]
  public var dimensions: [Dimension]
  public var currentDimensionIdentifier: Identifier
  public var worldName: Identifier
  public var hashedSeed: Int
  public var maxPlayers: UInt8
  public var viewDistance: Int
  public var reducedDebugInfo: Bool
  public var enableRespawnScreen: Bool
  public var isDebug: Bool
  public var isFlat: Bool

  public init(from packetReader: inout PacketReader) throws {
    playerEntityId = try packetReader.readInt()
    let gamemodeInt = Int8(try packetReader.readUnsignedByte())
    isHardcore = gamemodeInt & 0x8 == 0x8
    guard let gamemode = Gamemode(rawValue: gamemodeInt) else {
      throw ClientboundPacketError.invalidGamemode
    }
    self.gamemode = gamemode
    let previousGamemodeInt = try packetReader.readByte()
    previousGamemode = Gamemode(rawValue: previousGamemodeInt)
    worldCount = try packetReader.readVarInt()
    worldNames = []
    for _ in 0..<worldCount {
      worldNames.append(try packetReader.readIdentifier())
    }

    dimensions = []
    let dimensionCodec = try packetReader.readNBTCompound()
    let dimensionList: [NBT.Compound] = try dimensionCodec.getList("dimension")
    for compound in dimensionList {
      dimensions.append(try Dimension(from: compound))
    }

    currentDimensionIdentifier = try packetReader.readIdentifier()
    worldName = try packetReader.readIdentifier()
    hashedSeed = try packetReader.readLong()
    maxPlayers = try packetReader.readUnsignedByte()
    viewDistance = try packetReader.readVarInt()
    reducedDebugInfo = try packetReader.readBool()
    enableRespawnScreen = try packetReader.readBool()
    isDebug = try packetReader.readBool()
    isFlat = try packetReader.readBool()
  }

  public func handle(for client: Client) throws {
    guard let currentDimension = dimensions.first(where: { dimension in
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

    client.game.maxPlayers = Int(maxPlayers)
    client.game.maxViewDistance = viewDistance
    client.game.debugInfoReduced = reducedDebugInfo
    client.game.respawnScreenEnabled = enableRespawnScreen
    client.game.isHardcore = isHardcore
    client.game.dimensions = dimensions
  
    var oldPlayerEntityId: Int?
    client.game.accessPlayer { player in
      player.playerAttributes.previousGamemode = previousGamemode
      player.gamemode.gamemode = gamemode
      player.playerAttributes.isHardcore = isHardcore
      oldPlayerEntityId = player.entityId.id
    }

    if let oldPlayerEntityId = oldPlayerEntityId {
      client.game.updateEntityId(oldPlayerEntityId, to: playerEntityId)
    }

    client.game.changeWorld(to: world)

    // TODO: the event below should be dispatched from game instead of here. Event dispatching should
    //       be done in a way that makes it clear what will and what won't emit an event.
    client.eventBus.dispatch(JoinWorldEvent())

    try client.connection?.sendPacket(ClientSettingsPacket(client.configuration))

    client.connection?.hasJoined = true
  }
}
