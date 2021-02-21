//
//  TradeListPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation

struct TradeListPacket: ClientboundPacket {
  static let id: Int = 0x27
  
  var windowId: Int32
  var trades: [Trade]
  var villagerLevel: Int32
  var experience: Int32
  var isRegularVillager: Bool
  var canRestock: Bool
  
  struct Trade {
    var firstInputItem: Slot
    var outputItem: Slot
    var secondInputItem: Slot?
    var tradeDisabled: Bool
    var numUses: Int32 // number of uses so far
    var maxUses: Int32 // maximum number of uses before disabled
    var xp: Int32
    var specialPrice: Int32
    var priceMultiplier: Float
    var demand: Int32
  }
  
  init(from packetReader: inout PacketReader) throws {
    windowId = packetReader.readVarInt()
    
    trades = []
    let count = packetReader.readUnsignedByte()
    for _ in 0..<count {
      let firstInputItem = try packetReader.readSlot()
      let outputItem = try packetReader.readSlot()
      let hasSecondInputItem = packetReader.readBool()
      var secondInputItem: Slot? = nil
      if hasSecondInputItem {
        secondInputItem = try packetReader.readSlot()
      }
      let tradeDisabled = packetReader.readBool()
      let numUses = packetReader.readInt()
      let maxUses = packetReader.readInt()
      let xp = packetReader.readInt()
      let specialPrice = packetReader.readInt()
      let priceMultiplier = packetReader.readFloat()
      let demand = packetReader.readInt()
      let trade = Trade(firstInputItem: firstInputItem, outputItem: outputItem, secondInputItem: secondInputItem, tradeDisabled: tradeDisabled, numUses: numUses, maxUses: maxUses, xp: xp, specialPrice: specialPrice, priceMultiplier: priceMultiplier, demand: demand)
      trades.append(trade)
    }
    
    villagerLevel = packetReader.readVarInt()
    experience = packetReader.readVarInt()
    isRegularVillager = packetReader.readBool()
    canRestock = packetReader.readBool()
  }
}
