//
//  FileManager.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 16/7/21.
//

import Foundation

extension FileManager {
  func directoryExists(at url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    let itemExists = fileExists(atPath: url.path, isDirectory: &isDirectory)
    return itemExists && isDirectory.boolValue
  }
}
