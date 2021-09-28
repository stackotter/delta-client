//
//  WorldDescriptor.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 31/5/21.
//

import Foundation

public protocol WorldDescriptor {
  var worldName: Identifier { get }
  var dimension: Identifier { get }
  var hashedSeed: Int { get }
  var isDebug: Bool { get }
  var isFlat: Bool { get }
}
