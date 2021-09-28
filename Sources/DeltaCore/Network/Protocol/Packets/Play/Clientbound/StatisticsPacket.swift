import Foundation

public struct StatisticsPacket: ClientboundPacket {
  public static let id: Int = 0x06
  
  public var statistics: [Statistic]
  
  public init(from packetReader: inout PacketReader) throws {
    statistics = []
    
    let count = packetReader.readVarInt()
    for _ in 0..<count {
      let categoryId = packetReader.readVarInt()
      let statisticId = packetReader.readVarInt()
      let value = packetReader.readVarInt()
      let statistic = Statistic(categoryId: categoryId, statisticId: statisticId, value: value)
      statistics.append(statistic)
    }
  }
}
