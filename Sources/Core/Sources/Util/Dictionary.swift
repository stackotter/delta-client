import Foundation

extension Dictionary {
  init(values: [Value], keyedBy key: KeyPath<Value, Key>) {
    self.init()
    for value in values {
      self[value[keyPath: key]] = value
    }
  }

  mutating func mutatingEach(_ update: (Key, inout Value) -> Void) {
    for key in keys {
      update(key, &(self[key]!))
    }
  }
}
