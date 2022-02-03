import Foundation

extension Dictionary {
  mutating func mutatingEach(_ update: (Key, inout Value) -> Void) {
    for key in keys {
      update(key, &(self[key]!))
    }
  }
}
