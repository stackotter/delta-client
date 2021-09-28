//
//  SmokingRecipe.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 12/1/21.
//

import Foundation

struct SmokingRecipe: HeatRecipe {
  var group: String
  var ingredient: Ingredient
  var result: ItemStack
  
  var experience: Float
  var cookingTime: Int
}
