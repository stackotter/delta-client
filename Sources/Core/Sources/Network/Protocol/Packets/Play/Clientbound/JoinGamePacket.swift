import Foundation

public struct JoinGamePacket: ClientboundPacket, WorldDescriptor {
  public static let id: Int = 0x25

  public var playerEntityId: Int
  public var isHardcore: Bool
  public var gamemode: Gamemode
  public var previousGamemode: Gamemode?
  public var worldCount: Int
  public var worldNames: [Identifier]
  public var dimensionCodec: NBT.Compound
  public var dimension: Identifier
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
    dimensionCodec = try packetReader.readNBTCompound()
    dimension = try packetReader.readIdentifier()
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
    client.game.update(packet: self, client: client)

    // TODO: the event below should be dispatched from game instead of here. Event dispatching should
    //       be done in a way that makes it clear what will and what won't emit an event.
    client.eventBus.dispatch(JoinWorldEvent())

    try client.connection?.sendPacket(ClientSettingsPacket(client.configuration))
  }
}
