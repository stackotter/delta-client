//
//  Int.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 16/7/21.
//

import Foundation

extension Int {
  var isPowerOfTwo: Bool {
    return (self > 0) && (self & (self - 1) == 0)
  }
}
