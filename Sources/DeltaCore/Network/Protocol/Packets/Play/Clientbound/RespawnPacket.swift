import Foundation

public struct RespawnPacket: ClientboundPacket, WorldDescriptor {
  public static let id: Int = 0x3a
  
  public var dimension: Identifier
  public var worldName: Identifier
  public var hashedSeed: Int
  public var gamemode: Gamemode
  public var previousGamemode: Gamemode
  public var isDebug: Bool
  public var isFlat: Bool
  public var copyMetadata: Bool

  public init(from packetReader: inout PacketReader) throws {
    dimension = try packetReader.readIdentifier()
    worldName = try packetReader.readIdentifier()
    hashedSeed = packetReader.readLong()
    guard
      let gamemode = Gamemode(rawValue: packetReader.readByte()),
      let previousGamemode = Gamemode(rawValue: packetReader.readByte())
    else {
      throw ClientboundPacketError.invalidGamemode
    }
    self.gamemode = gamemode
    self.previousGamemode = previousGamemode
    isDebug = packetReader.readBool()
    isFlat = packetReader.readBool()
    copyMetadata = packetReader.readBool() // TODO_LATER: not used yet
  }
  
  public func handle(for client: Client) throws {
    if let world = client.server?.world {
      world.update(with: self)
    } else {
      client.server?.world = World(from: self)
    }
    
    client.server?.player.update(with: self)
    
    // TODO: get auto respawn working
    let clientStatus = ClientStatusPacket(action: .performRespawn)
    client.sendPacket(clientStatus)
  }
}
