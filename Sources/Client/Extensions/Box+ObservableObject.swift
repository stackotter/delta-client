import Combine
import DeltaCore

extension Box: ObservableObject {
  public var objectWillChange: ObservableObjectPublisher {
    ObservableObjectPublisher()
  }
}
