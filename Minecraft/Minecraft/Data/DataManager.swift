//
//  DataManager.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/3/21.
//

import Foundation

class DataManager {
  init() {
    var applicationSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    applicationSupportDirectory.appendingPathComponent("MinecraftSwiftEdition")
    
    
  }
}
