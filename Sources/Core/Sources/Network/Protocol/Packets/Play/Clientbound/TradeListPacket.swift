import Foundation

public struct TradeListPacket: ClientboundPacket {
  public static let id: Int = 0x27
  
  public var windowId: Int
  public var trades: [Trade]
  public var villagerLevel: Int
  public var experience: Int
  public var isRegularVillager: Bool
  public var canRestock: Bool
  
  public struct Trade {
    public var firstInputItem: ItemStack
    public var outputItem: ItemStack
    public var secondInputItem: ItemStack?
    public var tradeDisabled: Bool
    public var numUses: Int // number of uses so far
    public var maxUses: Int // maximum number of uses before disabled
    public var xp: Int
    public var specialPrice: Int
    public var priceMultiplier: Float
    public var demand: Int
  }
  
  public init(from packetReader: inout PacketReader) throws {
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
      let trade = Trade(
        firstInputItem: firstInputItem,
        outputItem: outputItem,
        secondInputItem: secondInputItem,
        tradeDisabled: tradeDisabled,
        numUses: numUses,
        maxUses: maxUses,
        xp: xp,
        specialPrice: specialPrice,
        priceMultiplier: priceMultiplier,
        demand: demand
      )
      trades.append(trade)
    }
    
    villagerLevel = packetReader.readVarInt()
    experience = packetReader.readVarInt()
    isRegularVillager = packetReader.readBool()
    canRestock = packetReader.readBool()
  }
}
