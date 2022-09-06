import Foundation

public struct LoginPluginRequestPacket: ClientboundPacket {
  public static let id: Int = 0x04

  public var messageId: Int
  public var channel: Identifier
  public var data: [UInt8]

  public init(from packetReader: inout PacketReader) throws {
    messageId = try packetReader.readVarInt()
    channel = try packetReader.readIdentifier()
    data = try packetReader.readByteArray(length: packetReader.remaining)
  }

  public func handle(for client: Client) throws {
    try client.sendPacket(LoginPluginResponsePacket(
      messageId: messageId,
      wasSuccess: false,
      data: []
    ))
  }
}
