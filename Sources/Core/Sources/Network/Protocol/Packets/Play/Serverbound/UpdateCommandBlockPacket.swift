import Foundation

public struct UpdateCommandBlockPacket: ServerboundPacket {
  public static let id: Int = 0x25
  
  public var location: Position
  public var command: String
  public var mode: CommandBlockMode
  public var flags: CommandBlockFlags
  
  public enum CommandBlockMode: Int32 {
    case sequence = 0
    case auto = 1
    case redstone = 2
  }
  
  public struct CommandBlockFlags: OptionSet {
    public let rawValue: UInt8
    
    public init(rawValue: UInt8) {
      self.rawValue = rawValue
    }
    
    public static let trackOutput = CommandBlockFlags(rawValue: 0x01)
    public static let isConditional = CommandBlockFlags(rawValue: 0x02)
    public static let automatic = CommandBlockFlags(rawValue: 0x04)
  }
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writePosition(location)
    writer.writeString(command)
    writer.writeVarInt(mode.rawValue)
    writer.writeUnsignedByte(flags.rawValue)
  }
}
