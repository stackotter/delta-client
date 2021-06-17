//
//  WorldBorderPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct WorldBorderPacket: ClientboundPacket {
  static let id: Int = 0x3d
  
  var action: WorldBorderAction
  
  enum WorldBorderAction {
    case setSize(diameter: Double)
    case lerpSize(oldDiameter: Double, newDiameter: Double, speed: Int)
    case setCenter(x: Double, z: Double)
    case initialise(action: InitialiseAction)
    case setWarningTime(warningTime: Int)
    case setWarningBlocks(warningBlocks: Int)
    
    struct InitialiseAction {
      var x: Double
      var z: Double
      var oldDiameter: Double
      var newDiameter: Double
      var speed: Int
      var portalTeleportBoundary: Int
      var warningTime: Int
      var warningBlocks: Int
    }
  }
  
  enum WorldBorderPacketError: LocalizedError {
    case invalidActionId
  }
  
  init(from packetReader: inout PacketReader) throws {
    let actionId = packetReader.readVarInt()
    switch actionId {
      case 0: // set size
        let diameter = packetReader.readDouble()
        action = .setSize(diameter: diameter)
      case 1: // lerp size
        let oldDiameter = packetReader.readDouble()
        let newDiameter = packetReader.readDouble()
        let speed = packetReader.readVarLong()
        action = .lerpSize(oldDiameter: oldDiameter, newDiameter: newDiameter, speed: speed)
      case 2: // set center
        let x = packetReader.readDouble()
        let z = packetReader.readDouble()
        action = .setCenter(x: x, z: z)
      case 3: // initialise
        let x = packetReader.readDouble()
        let z = packetReader.readDouble()
        let oldDiameter = packetReader.readDouble()
        let newDiameter = packetReader.readDouble()
        let speed = packetReader.readVarLong()
        let portalTeleportBoundary = packetReader.readVarInt()
        let warningTime = packetReader.readVarInt()
        let warningBlocks = packetReader.readVarInt()
        let initAction = WorldBorderAction.InitialiseAction(x: x, z: z, oldDiameter: oldDiameter, newDiameter: newDiameter,
                                                            speed: speed, portalTeleportBoundary: portalTeleportBoundary,
                                                            warningTime: warningTime, warningBlocks: warningBlocks)
        action = .initialise(action: initAction)
      case 4: // set warning time
        let warningTime = packetReader.readVarInt()
        action = .setWarningTime(warningTime: warningTime)
      case 5: // set warning blocks
        let warningBlocks = packetReader.readVarInt()
        action = .setWarningBlocks(warningBlocks: warningBlocks)
      default:
        throw WorldBorderPacketError.invalidActionId
    }
  }
}
