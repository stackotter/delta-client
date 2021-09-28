import Foundation

public struct SetExperiencePacket: ClientboundPacket {
  public static let id: Int = 0x48
  
  public var experienceBar: Float
  public var level: Int
  public var totalExperience: Int

  public init(from packetReader: inout PacketReader) throws {
    experienceBar = packetReader.readFloat()
    level = packetReader.readVarInt()
    totalExperience = packetReader.readVarInt()
  }
  
  public func handle(for client: Client) throws {
    client.server?.player.update(with: self)
  }
}
