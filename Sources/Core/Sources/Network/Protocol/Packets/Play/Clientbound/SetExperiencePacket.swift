import Foundation

public struct SetExperiencePacket: ClientboundPacket {
  public static let id: Int = 0x48
  
  public var experienceBar: Float
  public var level: Int
  public var totalExperience: Int

  public init(from packetReader: inout PacketReader) throws {
    experienceBar = try packetReader.readFloat()
    level = try packetReader.readVarInt()
    totalExperience = try packetReader.readVarInt()
  }
  
  public func handle(for client: Client) throws {
    client.game.accessPlayer { player in
      let experience = player.experience
      experience.experienceBarProgress = experienceBar
      experience.experienceLevel = level
      experience.experience = totalExperience
    }
  }
}
