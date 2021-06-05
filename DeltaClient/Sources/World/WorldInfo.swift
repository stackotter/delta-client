//
//  WorldInfo.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 31/5/21.
//

import Foundation

extension World {
  struct Info {
    var name: Identifier
    var dimension: Identifier
    var hashedSeed: Int
    var isDebug: Bool
    var isFlat: Bool
  }
}
