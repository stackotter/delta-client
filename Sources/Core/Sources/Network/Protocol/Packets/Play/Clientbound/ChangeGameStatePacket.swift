import Foundation

public struct ChangeGameStatePacket: ClientboundPacket {
  public static let id: Int = 0x1e

  public var reason: Reason
  public var value: Float

  public enum Reason: UInt8 {
    case noRespawnBlockAvailable
    case endRaining
    case beginRaining
    case changeGamemode
    case winGame
    case demoEvent
    case arrowHitPlayer
    case rainLevelChange
    case thunderLevelChange
    case playPufferfishStingSound
    case playElderGuardianMobAppearance
    case enableRespawnScreen
  }

  public init(from packetReader: inout PacketReader) throws {
    let byte = try packetReader.readUnsignedByte()
    guard let reason = Reason(rawValue: byte) else {
      throw ClientboundPacketError.invalidChangeGameStateReasonRawValue(byte)
    }
    self.reason = reason
    value = try packetReader.readFloat()
  }

  public func handle(for client: Client) throws {
    switch reason {
      case .changeGamemode:
        guard let gamemode = Gamemode(rawValue: Int8(value)) else {
          throw ClientboundPacketError.invalidGamemode
        }

        client.game.accessPlayer { player in
          player.gamemode.gamemode = gamemode
        }
      default:
        // TODO: Implement rest of ChangeGameStatePacket handling
        break
    }
  }
}
