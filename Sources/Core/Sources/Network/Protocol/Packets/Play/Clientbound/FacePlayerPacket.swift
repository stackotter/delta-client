import Foundation

public struct FacePlayerPacket: ClientboundPacket {
  public static let id: Int = 0x34

  public var feetOrEyes: Int
  public var targetPosition: EntityPosition
  public var isEntity: Bool
  public var entityId: Int?
  public var entityFeetOrEyes: Int?
  
  public init(from packetReader: inout PacketReader) throws {
    feetOrEyes = packetReader.readVarInt()
    targetPosition = packetReader.readEntityPosition()
    isEntity = packetReader.readBool()
    if isEntity {
      entityId = packetReader.readVarInt()
      entityFeetOrEyes = packetReader.readVarInt()
    }
  }
}
