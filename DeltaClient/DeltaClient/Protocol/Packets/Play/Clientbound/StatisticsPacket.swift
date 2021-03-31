//
//  StatisticsPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct StatisticsPacket: ClientboundPacket {
  static let id: Int = 0x06
  
  var statistics: [Statistic]
  
  init(from packetReader: inout PacketReader) throws {
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
