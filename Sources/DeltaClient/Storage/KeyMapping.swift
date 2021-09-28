import Foundation
import DeltaCore

struct KeyMapping {
  var mapping: [Input: Key]
  
  func getEvent(for key: Key) -> Input? {
    for (event, eventKey) in mapping {
      if key == eventKey {
        return event
      }
    }
    return nil
  }
}
