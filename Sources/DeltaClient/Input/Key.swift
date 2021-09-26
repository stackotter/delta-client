//
//  Key.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 10/7/21.
//

import Foundation

enum Key: Hashable {
  case code(Int)
  case modifier(ModifierKey)
}
