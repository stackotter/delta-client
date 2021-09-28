import Foundation

public struct StatusResponsePacket: ClientboundPacket {
  public static let id: Int = 0x00
  
  public var json: JSON
  
  public init(from packetReader: inout PacketReader) throws {
    json = try packetReader.readJSON()
  }
  
  public func handle(for pinger: Pinger) {
    guard
      let versionInfo = json.getJSON(forKey: "version"),
      let versionName = versionInfo.getString(forKey: "name"),
      let protocolVersion = versionInfo.getInt(forKey: "protocol"),
      let players = json.getJSON(forKey: "players"),
      let maxPlayers = players.getInt(forKey: "max"),
      let numPlayers = players.getInt(forKey: "online")
    else {
      log.warning("failed to parse status response json")
      return
    }
    
    // TODO: use a Codable struct instead of custom guard statement
    
    let pingInfo = PingInfo(
      versionName: versionName,
      protocolVersion: protocolVersion,
      maxPlayers: maxPlayers,
      numPlayers: numPlayers,
      description: "Ping Complete", // TODO: decode server description chat component
      modInfo: "")
    
    ThreadUtil.runInMain {
      log.debug("Received ping response from \(pinger.connection?.socketAddress ?? "Unknown??")")
      pinger.pingResult = Result.success(pingInfo)
    }
    pinger.closeConnection()
  }
}
