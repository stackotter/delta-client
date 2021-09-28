//
//  Profiler.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 27/3/21.
//

import Foundation
import os

struct Profiler {
  var log: OSLog
  
  init(name: String) {
    log = OSLog(subsystem: "profiling", category: name)
  }
  
  func placeSignpost(type: OSSignpostType, name: StaticString) {
    os_signpost(type, log: log, name: name)
  }
}
