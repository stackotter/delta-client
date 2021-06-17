//
//  Observable.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 31/5/21.
//

import Foundation

class Observable {
  var updateHandlers: [(Event) -> Void] = []
  
  func registerUpdateHandler(_ handler: @escaping (Event) -> Void) {
    updateHandlers.append(handler)
  }
  
  func notifyObservers(_ event: Event) {
    updateHandlers.forEach { $0(event) }
  }
}
