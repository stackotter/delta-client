//
//  MapDataPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation

struct MapDataPacket: ClientboundPacket {
  static let id: Int = 0x26
  
  var mapId: Int32
  var scale: Int8
  var trackingPosition: Bool
  var locked: Bool
  var icons: [MapIcon]
  var columns: UInt8
  
  struct MapIcon {
    var type: Int32
    var x: Int8
    var z: Int8
    var direction: Int8
    var displayName: String?
  }
  
  init(fromReader packetReader: inout PacketReader) throws {
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
      var displayName: String? = nil
      if hasDisplayName {
        displayName = packetReader.readChat()
      }
      let icon = MapIcon(type: type, x: x, z: z, direction: direction, displayName: displayName)
      icons.append(icon)
    }
    
    columns = packetReader.readUnsignedByte()
    if columns > 0 {
      let _ = packetReader.readByte() // rows
      let _ = packetReader.readByte() // x
      let _ = packetReader.readByte() // z
      let length = packetReader.readVarInt()
      var data: [UInt8] = []
      for _ in 0..<length {
        data.append(packetReader.readUnsignedByte())
      }
    }
  }
}
