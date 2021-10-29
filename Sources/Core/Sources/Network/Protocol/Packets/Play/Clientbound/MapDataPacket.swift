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
    mapId = packetReader.readVarInt()
    scale = packetReader.readByte()
    trackingPosition = packetReader.readBool()
    locked = packetReader.readBool()
    
    icons = []
    let iconCount = packetReader.readVarInt()
    for _ in 0..<iconCount {
      let type = packetReader.readVarInt()
      let x = packetReader.readByte()
      let z = packetReader.readByte()
      let direction = packetReader.readByte()
      let hasDisplayName = packetReader.readBool()
      var displayName: ChatComponent?
      if hasDisplayName {
        displayName = try packetReader.readChat()
      }
      let icon = MapIcon(type: type, x: x, z: z, direction: direction, displayName: displayName)
      icons.append(icon)
    }
    
    columns = packetReader.readUnsignedByte()
    if columns > 0 {
      _ = packetReader.readByte() // rows
      _ = packetReader.readByte() // x
      _ = packetReader.readByte() // z
      let length = packetReader.readVarInt()
      var data: [UInt8] = []
      for _ in 0..<length {
        data.append(packetReader.readUnsignedByte())
      }
    }
  }
}
