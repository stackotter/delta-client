//
//  RecipeBookDataPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct RecipeBookDataPacket: ServerboundPacket {
  static let id: Int = 0x1e
  
  var data: RecipeBookData
  
  enum RecipeBookData {
    case displayedRecipe(recipeId: Identifier)
    case recipeBookStates(state: RecipeBookState)
  }
  
  struct RecipeBookState {
    var craftingRecipeBookOpen: Bool
    var craftingRecipeFilterActive: Bool
    var smeltingRecipeBookOpen: Bool
    var smeltingRecipeFilterActive: Bool
    var blastingRecipeBookOpen: Bool
    var blastingRecipeFilterActive: Bool
    var smokingRecipeBookOpen: Bool
    var smokingRecipeFilterActive: Bool
  }
  
  func writePayload(to writer: inout PacketWriter) {
    switch data {
      case let .displayedRecipe(recipeId: recipeId):
        writer.writeVarInt(0) // displayed recipes
        writer.writeIdentifier(recipeId)
      case let .recipeBookStates(state: state):
        writer.writeVarInt(1) // recipe book states
        writer.writeBool(state.craftingRecipeBookOpen)
        writer.writeBool(state.craftingRecipeFilterActive)
        writer.writeBool(state.smeltingRecipeBookOpen)
        writer.writeBool(state.smeltingRecipeFilterActive)
        writer.writeBool(state.blastingRecipeBookOpen)
        writer.writeBool(state.blastingRecipeFilterActive)
        writer.writeBool(state.smokingRecipeBookOpen)
        writer.writeBool(state.smokingRecipeFilterActive)
    }
  }
}
