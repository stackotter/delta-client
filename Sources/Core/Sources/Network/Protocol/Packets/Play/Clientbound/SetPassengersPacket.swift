import Foundation

public struct SetPassengersPacket: ClientboundPacket {
  public static let id: Int = 0x4b
  
  public var entityId: Int
  public var passengers: [Int]

  public init(from packetReader: inout PacketReader) throws {
    entityId = try packetReader.readVarInt()
    
    passengers = []
    let count = try packetReader.readVarInt()
    for _ in 0..<count {
      let passenger = try packetReader.readVarInt()
      passengers.append(passenger)
    }
  }
}
