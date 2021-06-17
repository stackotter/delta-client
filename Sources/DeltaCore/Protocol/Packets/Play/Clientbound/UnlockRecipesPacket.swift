//
//  UnlockRecipesPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct UnlockRecipesPacket: ClientboundPacket {
  static let id: Int = 0x36
  
  var action: Int
  var craftingRecipeBookOpen: Bool
  var craftingRecipeBookFilterActive: Bool
  var smeltingRecipeBookOpen: Bool
  var smeltingRecipeBookFilterActive: Bool
  var recipeIds: [Identifier]
  var initRecipeIds: [Identifier]?

  init(from packetReader: inout PacketReader) throws {
    action = packetReader.readVarInt()
    craftingRecipeBookOpen = packetReader.readBool()
    craftingRecipeBookFilterActive = packetReader.readBool()
    smeltingRecipeBookOpen = packetReader.readBool()
    smeltingRecipeBookFilterActive = packetReader.readBool()
    
    recipeIds = []
    var count = packetReader.readVarInt()
    for _ in 0..<count {
      let identifier = try packetReader.readIdentifier()
      recipeIds.append(identifier)
    }
    
    if action == 0 { // init
      var initRecipeIds = [Identifier]()
      count = packetReader.readVarInt()
      for _ in 0..<count {
        let identifier = try packetReader.readIdentifier()
        initRecipeIds.append(identifier)
      }
      self.initRecipeIds = initRecipeIds
    }
  }
}
