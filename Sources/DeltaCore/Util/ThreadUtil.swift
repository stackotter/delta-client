import Foundation

public struct ThreadUtil {
  public static func runInMain(_ closure: () -> Void) {
    if Thread.isMainThread {
      closure()
    } else {
      DispatchQueue.main.sync {
        closure()
      }
    }
  }
}
