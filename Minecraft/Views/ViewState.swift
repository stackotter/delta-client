//
//  ViewState.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/3/21.
//

import Foundation

class ViewState<T>: ObservableObject {
  @Published var state: T
  
  init(initialState: T) {
    state = initialState
  }
  
  func update(to newState: T) {
    if Thread.isMainThread {
      self.state = newState
    } else {
      DispatchQueue.main.sync {
        self.state = newState
      }
    }
  }
}
