import Foundation

public struct StatusResponsePacket: ClientboundPacket {
  public static let id: Int = 0x00

  public var response: StatusResponse

  public init(from packetReader: inout PacketReader) throws {
    let json = try packetReader.readString()

    guard let data = json.data(using: .utf8) else {
      throw ClientboundPacketError.invalidJSONString
    }

    response = try JSONDecoder().decode(StatusResponse.self, from: data)
  }

  public func handle(for pinger: Pinger) throws {
    ThreadUtil.runInMain {
      log.debug("Received ping response from \(pinger.descriptor.description)")
      pinger.response = Result.success(response)
      pinger.closeConnection()
    }
  }
}
