import SwiftUI
import DeltaCore

class Modal: ObservableObject {
  enum Content {
    case warning(String)
    case errorMessage(String)
    case error(Error)

    var message: String {
      switch self {
        case let .warning(message):
          return message
        case let .errorMessage(message):
          return message
        case let .error(error):
          if let richError = error as? RichError {
            return richError.richDescription
          } else {
            return error.localizedDescription
          }
      }
    }
  }

  var isPresented: Binding<Bool> {
    Binding {
      self.content != nil
    } set: { newValue in
      if !newValue {
        self.content = nil
        self.dismissHandler?()
      }
    }
  }

  @Published var content: Content?

  private var dismissHandler: (() -> Void)?
  /// Handlers to call when an error occurs. Guaranteed to be called on the
  /// main thread.
  private var errorHandlers: [(Error) -> Void] = []

  func onError(_ action: @escaping (Error) -> Void) {
    errorHandlers.append(action)
  }

  func warning(_ message: String, onDismiss dismissHandler: (() -> Void)? = nil) {
    log.warning(message)
    ThreadUtil.runInMain {
      content = .warning(message)
      self.dismissHandler = dismissHandler
    }
  }

  func error(_ message: String, onDismiss dismissHandler: (() -> Void)? = nil) {
    log.error(message)
    ThreadUtil.runInMain {
      content = .errorMessage(message)
      self.dismissHandler = dismissHandler
      for errorHandler in errorHandlers {
        errorHandler(RichError(message))
      }
    }
  }

  func error(_ error: Error, onDismiss dismissHandler: (() -> Void)? = nil) {
    log.error(error.localizedDescription)
    ThreadUtil.runInMain {
      content = .error(error)
      self.dismissHandler = dismissHandler
      for errorHandler in errorHandlers {
        errorHandler(error)
      }
    }
  }
}
