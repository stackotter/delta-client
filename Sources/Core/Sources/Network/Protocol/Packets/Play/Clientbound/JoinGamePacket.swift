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
    playerEntityId = packetReader.readInt()
    let gamemodeInt = Int8(packetReader.readUnsignedByte())
    isHardcore = gamemodeInt & 0x8 == 0x8
    guard let gamemode = Gamemode(rawValue: gamemodeInt) else {
      throw ClientboundPacketError.invalidGamemode
    }
    self.gamemode = gamemode
    let previousGamemodeInt = packetReader.readByte()
    previousGamemode = Gamemode(rawValue: previousGamemodeInt)
    worldCount = packetReader.readVarInt()
    worldNames = []
    for _ in 0..<worldCount {
      worldNames.append(try packetReader.readIdentifier())
    }
    dimensionCodec = try packetReader.readNBTCompound()
    dimension = try packetReader.readIdentifier()
    worldName = try packetReader.readIdentifier()
    hashedSeed = packetReader.readLong()
    maxPlayers = packetReader.readUnsignedByte()
    viewDistance = packetReader.readVarInt()
    reducedDebugInfo = packetReader.readBool()
    enableRespawnScreen = packetReader.readBool()
    isDebug = packetReader.readBool()
    isFlat = packetReader.readBool()
  }
  
  public func handle(for client: Client) throws {
    client.game.update(packet: self, client: client)
    
    // TODO: the event below should be dispatched from game instead of here. Event dispatching should be done in a way that makes it clear what will and what won't emit an event.
    client.eventBus.dispatch(JoinWorldEvent())
  }
}
