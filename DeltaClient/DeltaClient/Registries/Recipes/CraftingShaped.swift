//
//  CraftingShaped.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 12/1/21.
//

import Foundation

struct CraftingShaped: CraftingRecipe {
  var group: String
  
  var width: Int
  var height: Int
  var ingredients: [Ingredient]
  
  var result: ItemStack
}
