//
//  TradeListPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation

struct TradeListPacket: ClientboundPacket {
  static let id: Int = 0x27
  
  var windowId: Int
  var trades: [Trade]
  var villagerLevel: Int
  var experience: Int
  var isRegularVillager: Bool
  var canRestock: Bool
  
  struct Trade {
    var firstInputItem: ItemStack
    var outputItem: ItemStack
    var secondInputItem: ItemStack?
    var tradeDisabled: Bool
    var numUses: Int // number of uses so far
    var maxUses: Int // maximum number of uses before disabled
    var xp: Int
    var specialPrice: Int
    var priceMultiplier: Float
    var demand: Int
  }
  
  init(from packetReader: inout PacketReader) throws {
    windowId = packetReader.readVarInt()
    
    trades = []
    let count = packetReader.readUnsignedByte()
    for _ in 0..<count {
      let firstInputItem = try packetReader.readItemStack()
      let outputItem = try packetReader.readItemStack()
      let hasSecondInputItem = packetReader.readBool()
      var secondInputItem: ItemStack?
      if hasSecondInputItem {
        secondInputItem = try packetReader.readItemStack()
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
