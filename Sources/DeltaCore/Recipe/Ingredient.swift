//
//  Ingredient.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 12/1/21.
//

import Foundation

public struct Ingredient {
  public var ingredients: [ItemStack]
  public var count: Int {
    return ingredients.count
  }
}
