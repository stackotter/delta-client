import Foundation

public struct UnlockRecipesPacket: ClientboundPacket {
  public static let id: Int = 0x36
  
  public var action: Int
  public var craftingRecipeBookOpen: Bool
  public var craftingRecipeBookFilterActive: Bool
  public var smeltingRecipeBookOpen: Bool
  public var smeltingRecipeBookFilterActive: Bool
  public var recipeIds: [Identifier]
  public var initRecipeIds: [Identifier]?

  public init(from packetReader: inout PacketReader) throws {
    action = try packetReader.readVarInt()
    craftingRecipeBookOpen = try packetReader.readBool()
    craftingRecipeBookFilterActive = try packetReader.readBool()
    smeltingRecipeBookOpen = try packetReader.readBool()
    smeltingRecipeBookFilterActive = try packetReader.readBool()
    
    recipeIds = []
    var count = try packetReader.readVarInt()
    for _ in 0..<count {
      let identifier = try packetReader.readIdentifier()
      recipeIds.append(identifier)
    }
    
    if action == 0 { // init
      var initRecipeIds = [Identifier]()
      count = try packetReader.readVarInt()
      for _ in 0..<count {
        let identifier = try packetReader.readIdentifier()
        initRecipeIds.append(identifier)
      }
      self.initRecipeIds = initRecipeIds
    }
  }
}
