import Combine
import DeltaCore

extension TaskProgress: ObservableObject {
  public var objectWillChange: ObservableObjectPublisher {
    let publisher = ObservableObjectPublisher()
    onChange { _ in
      ThreadUtil.runInMain {
        publisher.send()
      }
    }
    return publisher
  }
}
