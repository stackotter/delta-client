//
//  ViewState.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/3/21.
//

import Foundation

class ViewState<T>: ObservableObject {
  @Published var value: T
  var previous: T
  
  init(initialState: T) {
    self.value = initialState
    self.previous = initialState
  }
  
  func update(to newState: T) {
    ThreadUtil.runInMain {
      self.previous = self.value
      self.value = newState
    }
  }
}
