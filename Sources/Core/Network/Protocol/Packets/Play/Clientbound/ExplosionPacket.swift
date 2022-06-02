import Foundation

public struct ExplosionPacket: ClientboundPacket {
  public static let id: Int = 0x1c
  
  public var x: Float
  public var y: Float
  public var z: Float
  public var strength: Float
  public var records: [(Int8, Int8, Int8)] // swiftlint:disable:this large_tuple
  public var playerMotionX: Float
  public var playerMotionY: Float
  public var playerMotionZ: Float
  
  public init(from packetReader: inout PacketReader) throws {
    x = try packetReader.readFloat()
    y = try packetReader.readFloat()
    z = try packetReader.readFloat()
    strength = try packetReader.readFloat()
    
    records = []
    let recordCount = try packetReader.readInt()
    for _ in 0..<recordCount {
      let record = (
        try packetReader.readByte(),
        try packetReader.readByte(),
        try packetReader.readByte()
      )
      records.append(record)
    }
    
    playerMotionX = try packetReader.readFloat()
    playerMotionY = try packetReader.readFloat()
    playerMotionZ = try packetReader.readFloat()
  }
}
