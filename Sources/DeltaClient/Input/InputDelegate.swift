//
//  InputDelegate.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 10/7/21.
//

import Foundation

protocol InputDelegate: AnyObject {
  func onKeyDown(_ key: Key)
  func onKeyUp(_ key: Key)
  func onMouseMove(_ deltaX: Float, _ deltaY: Float)
}

extension InputDelegate {
  func onKeyDown(_ key: Key) { }
  func onKeyUp(_ key: Key) { }
  func onMouseMove(_ deltaX: Float, _ deltaY: Float) { }
}
