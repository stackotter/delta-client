import Foundation

public enum WorldBorderPacketError: LocalizedError {
  case invalidActionId(Int)
  
  public var errorDescription: String? {
    switch self {
      case .invalidActionId(let id):
        return "Invalid action Id: \(id)"
    }
  }
}

public struct WorldBorderPacket: ClientboundPacket {
  public static let id: Int = 0x3d
  
  public var action: WorldBorderAction
  
  public enum WorldBorderAction {
    case setSize(diameter: Double)
    case lerpSize(oldDiameter: Double, newDiameter: Double, speed: Int)
    case setCenter(x: Double, z: Double)
    case initialise(action: InitialiseAction)
    case setWarningTime(warningTime: Int)
    case setWarningBlocks(warningBlocks: Int)
    
    public struct InitialiseAction {
      public var x: Double
      public var z: Double
      public var oldDiameter: Double
      public var newDiameter: Double
      public var speed: Int
      public var portalTeleportBoundary: Int
      public var warningTime: Int
      public var warningBlocks: Int
    }
  }
  
  public init(from packetReader: inout PacketReader) throws {
    let actionId = try packetReader.readVarInt()
    switch actionId {
      case 0: // set size
        let diameter = try packetReader.readDouble()
        action = .setSize(diameter: diameter)
      case 1: // lerp size
        let oldDiameter = try packetReader.readDouble()
        let newDiameter = try packetReader.readDouble()
        let speed = try packetReader.readVarLong()
        action = .lerpSize(oldDiameter: oldDiameter, newDiameter: newDiameter, speed: speed)
      case 2: // set center
        let x = try packetReader.readDouble()
        let z = try packetReader.readDouble()
        action = .setCenter(x: x, z: z)
      case 3: // initialise
        let x = try packetReader.readDouble()
        let z = try packetReader.readDouble()
        let oldDiameter = try packetReader.readDouble()
        let newDiameter = try packetReader.readDouble()
        let speed = try packetReader.readVarLong()
        let portalTeleportBoundary = try packetReader.readVarInt()
        let warningTime = try packetReader.readVarInt()
        let warningBlocks = try packetReader.readVarInt()
        let initAction = WorldBorderAction.InitialiseAction(
          x: x,
          z: z,
          oldDiameter: oldDiameter,
          newDiameter: newDiameter,
          speed: speed,
          portalTeleportBoundary: portalTeleportBoundary,
          warningTime: warningTime,
          warningBlocks: warningBlocks
        )
        action = .initialise(action: initAction)
      case 4: // set warning time
        let warningTime = try packetReader.readVarInt()
        action = .setWarningTime(warningTime: warningTime)
      case 5: // set warning blocks
        let warningBlocks = try packetReader.readVarInt()
        action = .setWarningBlocks(warningBlocks: warningBlocks)
      default:
        throw WorldBorderPacketError.invalidActionId(actionId)
    }
  }
}
