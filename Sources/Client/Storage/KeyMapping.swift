import Foundation
import DeltaCore

public struct KeyMapping: Codable {
  public var mapping: [Input: Key]
  
  public func getEvent(for key: Key) -> Input? {
    for (event, eventKey) in mapping {
      if key == eventKey {
        return event
      }
    }
    return nil
  }
}
