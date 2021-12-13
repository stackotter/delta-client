import Foundation
import DeltaCore

/// An observable wrapper around a state enum for use with SwiftUI
final class StateWrapper<State>: ObservableObject {
  @Published private(set) var current: State
  private var history: [State] = []
  
  /// Create a new state wrapper with the specified initial state
  init(initial: State) {
    current = initial
  }
  
  /// Update the app state to the state specified, on the main thread.
  func update(to newState: State) {
    ThreadUtil.runInMain {
      // Update state
      let current = self.current
      self.current = newState
      
      // Simplify state history
      if let index = history.firstIndex(where: { name(of: $0) == name(of: current) }) {
        history.removeLast(history.count - index)
      }
      if let index = history.firstIndex(where: { name(of: $0) == name(of: newState) }) {
        history.removeLast(history.count - index)
      }
      
      // Update state history
      history.append(current)
    }
  }
  
  /// Return to the previous app state
  func pop() {
    ThreadUtil.runInMain {
      if !history.isEmpty {
        let previousState = history.removeLast()
        update(to: previousState)
      } else {
        print("failed to pop app state, no previous state to return to") // TODO: proper logger
      }
    }
  }
  
  private func name(of state: State) -> String {
    return String(describing: state)
  }
}
