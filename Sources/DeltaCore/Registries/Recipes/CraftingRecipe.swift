//
//  CraftingRecipe.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 12/1/21.
//

import Foundation

protocol CraftingRecipe {
  var group: String { get }
  var ingredients: [Ingredient] { get }
  var result: ItemStack { get }
}
