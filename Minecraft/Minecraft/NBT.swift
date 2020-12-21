//
//  NBT.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 15/12/20.
//

import Foundation

struct NBT {
  var root: NBTCompound
  
  static func fromURL(_ url: URL) -> NBT {
    let data: Data
    do {
      data = try Data(contentsOf: url)
    } catch {
      fatalError("couldn't open url to read nbt data")
    }
    let bytes = [UInt8](data)
    let compound = NBTCompound.fromBytes(bytes)
    let nbt = NBT(root: compound)
    return nbt
  }
}
