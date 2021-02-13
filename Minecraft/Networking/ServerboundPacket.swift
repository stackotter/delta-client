//
//  ServerboundPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation

protocol ServerboundPacket {
  static var id: Int { get }
  
  func toBytes() -> [UInt8]
}

extension ServerboundPacket {
  var id: Int {
    return type(of: self).id
  }
}
