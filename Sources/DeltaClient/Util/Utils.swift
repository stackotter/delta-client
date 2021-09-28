//
//  Utils.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 28/9/21.
//

import Foundation

enum Utils {
  static func shell(_ command: String) {
    let task = Process()
    task.arguments = ["-c", command]
    task.launchPath = "/bin/bash"
    task.launch()
  }
}
