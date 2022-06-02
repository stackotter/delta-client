import Foundation

public struct EncryptionResponsePacket: ServerboundPacket {
  public static let id: Int = 0x01
  
  public var sharedSecret: [UInt8]
  public var verifyToken: [UInt8]
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(Int32(sharedSecret.count))
    writer.writeByteArray(sharedSecret)
    writer.writeVarInt(Int32(verifyToken.count))
    writer.writeByteArray(verifyToken)
  }
}
