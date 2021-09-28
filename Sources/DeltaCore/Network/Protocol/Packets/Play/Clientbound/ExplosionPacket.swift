import Foundation

public struct ExplosionPacket: ClientboundPacket {
  public static let id: Int = 0x1c
  
  public var x: Float
  public var y: Float
  public var z: Float
  public var strength: Float
  public var records: [(Int8, Int8, Int8)]
  public var playerMotionX: Float
  public var playerMotionY: Float
  public var playerMotionZ: Float
  
  public init(from packetReader: inout PacketReader) throws {
    x = packetReader.readFloat()
    y = packetReader.readFloat()
    z = packetReader.readFloat()
    strength = packetReader.readFloat()
    
    records = []
    let recordCount = packetReader.readInt()
    for _ in 0..<recordCount {
      let record = (
        packetReader.readByte(),
        packetReader.readByte(),
        packetReader.readByte()
      )
      records.append(record)
    }
    
    playerMotionX = packetReader.readFloat()
    playerMotionY = packetReader.readFloat()
    playerMotionZ = packetReader.readFloat()
  }
}
