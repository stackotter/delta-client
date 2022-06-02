import Foundation

public struct MapDataPacket: ClientboundPacket {
  public static let id: Int = 0x26
  
  public var mapId: Int
  public var scale: Int8
  public var trackingPosition: Bool
  public var locked: Bool
  public var icons: [MapIcon]
  public var columns: UInt8
  
  public struct MapIcon {
    var type: Int
    var x: Int8
    var z: Int8
    var direction: Int8
    var displayName: ChatComponent?
  }
  
  public init(from packetReader: inout PacketReader) throws {
    mapId = try packetReader.readVarInt()
    scale = try packetReader.readByte()
    trackingPosition = try packetReader.readBool()
    locked = try packetReader.readBool()
    
    icons = []
    let iconCount = try packetReader.readVarInt()
    for _ in 0..<iconCount {
      let type = try packetReader.readVarInt()
      let x = try packetReader.readByte()
      let z = try packetReader.readByte()
      let direction = try packetReader.readByte()
      let hasDisplayName = try packetReader.readBool()
      var displayName: ChatComponent?
      if hasDisplayName {
        displayName = try packetReader.readChat()
      }
      let icon = MapIcon(type: type, x: x, z: z, direction: direction, displayName: displayName)
      icons.append(icon)
    }
    
    columns = try packetReader.readUnsignedByte()
    if columns > 0 {
      _ = try packetReader.readByte() // rows
      _ = try packetReader.readByte() // x
      _ = try packetReader.readByte() // z
      let length = try packetReader.readVarInt()
      var data: [UInt8] = []
      for _ in 0..<length {
        data.append(try packetReader.readUnsignedByte())
      }
    }
  }
}
