//
//  AppState.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/3/21.
//

import Foundation

class AppState: ObservableObject {
  @Published var state: AppStateEnum
  
  init(initialState: AppStateEnum) {
    self.state = initialState
  }
  
  enum AppStateEnum {
    case loading(message: String)
    case error(message: String)
    case loaded(managers: Managers)
  }
  
  func displayLoadingScreenMessage(_ message: String) {
    DispatchQueue.main.sync {
      state = .loading(message: message)
    }
  }
  
  func finishLoading(withManagers managers: Managers) {
    DispatchQueue.main.sync {
      state = .loaded(managers: managers)
    }
  }
  
  func displayError(_ message: String) {
    DispatchQueue.main.sync {
      state = .error(message: message)
    }
  }
}
