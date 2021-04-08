//
//  HeatRecipe.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 12/1/21.
//

import Foundation

// encompasses smelting, blasting, smoking and campfire cooking
protocol HeatRecipe {
  var group: String { get }
  var ingredient: Ingredient { get }
  var result: ItemStack { get }

  var experience: Float { get }
  var cookingTime: Int { get }
}
