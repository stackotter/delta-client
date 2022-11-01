import Foundation
import FirebladeMath

public struct FacePlayerPacket: ClientboundPacket {
  public static let id: Int = 0x34

  public var feetOrEyes: Int
  public var targetPosition: Vec3d
  public var isEntity: Bool
  public var entityId: Int?
  public var entityFeetOrEyes: Int?

  public init(from packetReader: inout PacketReader) throws {
    feetOrEyes = try packetReader.readVarInt()
    targetPosition = try packetReader.readEntityPosition()
    isEntity = try packetReader.readBool()
    if isEntity {
      entityId = try packetReader.readVarInt()
      entityFeetOrEyes = try packetReader.readVarInt()
    }
  }
}
