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
      previous = value
      value = newState
    }
  }
  
  func update(to newState: T, returnTo previousState: T) {
    ThreadUtil.runInMain {
      previous = previousState
      value = newState
    }
  }
  
  func returnToPrevious() {
    ThreadUtil.runInMain {
      let saved = value
      value = previous
      previous = saved
    }
  }
}
