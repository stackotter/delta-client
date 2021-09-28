//
//  ThreadUtil.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 7/4/21.
//

import Foundation

public struct ThreadUtil {
  public static func runInMain(_ closure: () -> Void) {
    if Thread.isMainThread {
      closure()
    } else {
      DispatchQueue.main.sync {
        closure()
      }
    }
  }
}
