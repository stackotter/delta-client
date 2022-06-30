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
    public var firstInputItem: Slot
    public var outputItem: Slot
    public var secondInputItem: Slot?
    public var tradeDisabled: Bool
    public var numUses: Int // number of uses so far
    public var maxUses: Int // maximum number of uses before disabled
    public var xp: Int
    public var specialPrice: Int
    public var priceMultiplier: Float
    public var demand: Int
  }

  public init(from packetReader: inout PacketReader) throws {
    windowId = try packetReader.readVarInt()

    trades = []
    let count = try packetReader.readUnsignedByte()
    for _ in 0..<count {
      let firstInputItem = try packetReader.readSlot()
      let outputItem = try packetReader.readSlot()
      let hasSecondInputItem = try packetReader.readBool()
      var secondInputItem: Slot?
      if hasSecondInputItem {
        secondInputItem = try packetReader.readSlot()
      }
      let tradeDisabled = try packetReader.readBool()
      let numUses = try packetReader.readInt()
      let maxUses = try packetReader.readInt()
      let xp = try packetReader.readInt()
      let specialPrice = try packetReader.readInt()
      let priceMultiplier = try packetReader.readFloat()
      let demand = try packetReader.readInt()
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

    villagerLevel = try packetReader.readVarInt()
    experience = try packetReader.readVarInt()
    isRegularVillager = try packetReader.readBool()
    canRestock = try packetReader.readBool()
  }
}
