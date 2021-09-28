import Foundation

public struct PlayerAbilitiesPacket: ClientboundPacket {
  public static let id: Int = 0x31
  
  public var flags: PlayerAbilities
  public var flyingSpeed: Float
  public var fovModifier: Float
  
  public init(from packetReader: inout PacketReader) {
    flags = PlayerAbilities(rawValue: packetReader.readUnsignedByte())
    flyingSpeed = packetReader.readFloat()
    fovModifier = packetReader.readFloat()
  }
  
  public func handle(for client: Client) throws {
    client.server?.player.update(with: self)
  }
}
