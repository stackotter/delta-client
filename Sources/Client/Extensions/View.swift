import SwiftUI

extension View {
  /// Returns a copy of self with the specified property set to the given value.
  /// Useful for implementing custom view modifiers.
  func with<T>(_ keyPath: WritableKeyPath<Self, T>, _ value: T) -> Self {
    var view = self
    view[keyPath: keyPath] = value
    return view
  }

  /// Appends an action to an action stored property. Useful for implementing custom
  /// view modifiers such as `onClick` etc. Allows the modifier to be called multiple
  /// times without overwriting previous actions. If the stored action is nil, the
  /// given action becomes the stored action, otherwise the new action is appended to
  /// the existing action.
  func appendingAction<T>(
    to keyPath: WritableKeyPath<Self, ((T) -> Void)?>,
    _ action: @escaping (T) -> Void
  ) -> Self {
    with(keyPath) { argument in
      self[keyPath: keyPath]?(argument)
      action(argument)
    }
  }

  /// Appends an action to an action stored property. Useful for implementing custom
  /// view modifiers such as `onClick` etc. Allows the modifier to be called multiple
  /// times without overwriting previous actions. If the stored action is nil, the
  /// given action becomes the stored action, otherwise the new action is appended to
  /// the existing action.
  func appendingAction<T, U>(
    to keyPath: WritableKeyPath<Self, ((T, U) -> Void)?>,
    _ action: @escaping (T, U) -> Void
  ) -> Self {
    with(keyPath) { argument1, argument2 in
      self[keyPath: keyPath]?(argument1, argument2)
      action(argument1, argument2)
    }
  }

  /// Appends an action to an action stored property. Useful for implementing custom
  /// view modifiers such as `onClick` etc. Allows the modifier to be called multiple
  /// times without overwriting previous actions. If the stored action is nil, the
  /// given action becomes the stored action, otherwise the new action is appended to
  /// the existing action.
  func appendingAction<T, U, V>(
    to keyPath: WritableKeyPath<Self, ((T, U, V) -> Void)?>,
    _ action: @escaping (T, U, V) -> Void
  ) -> Self {
    with(keyPath) { argument1, argument2, argument3 in
      self[keyPath: keyPath]?(argument1, argument2, argument3)
      action(argument1, argument2, argument3)
    }
  }

  /// Appends an action to an action stored property. Useful for implementing custom
  /// view modifiers such as `onClick` etc. Allows the modifier to be called multiple
  /// times without overwriting previous actions. If the stored action is nil, the
  /// given action becomes the stored action, otherwise the new action is appended to
  /// the existing action.
  func appendingAction<T, U, V, W>(
    to keyPath: WritableKeyPath<Self, ((T, U, V, W) -> Void)?>,
    _ action: @escaping (T, U, V, W) -> Void
  ) -> Self {
    with(keyPath) { argument1, argument2, argument3, argument4 in
      self[keyPath: keyPath]?(argument1, argument2, argument3, argument4)
      action(argument1, argument2, argument3, argument4)
    }
  }
}
