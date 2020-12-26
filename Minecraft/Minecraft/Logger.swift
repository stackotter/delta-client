//
//  Logger.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 24/12/20.
//

import Foundation
import os

extension Logger {
  init(for object: Any, desc: String? = nil) {
    let subsystem = Bundle.main.bundleIdentifier!
    let category = String(describing: object)
    self.init(subsystem: subsystem, category: desc == nil ? category : "\(category) \(desc!)")
  }
}
