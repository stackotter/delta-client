//
//  Ingredient.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 12/1/21.
//

import Foundation

struct Ingredient {
  var ingredients: [ItemStack]
  var count: Int {
    return ingredients.count
  }
}
