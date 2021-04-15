//
//  EventProtocol.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 15/4/21.
//

import Foundation

protocol EventProtocol { }

extension EventProtocol {
  var name:String {
    let mirror = Mirror(reflecting: self)
    if let name = mirror.children.first?.label {
      return name
    } else {
      return String(describing:self)
    }
  }
}
