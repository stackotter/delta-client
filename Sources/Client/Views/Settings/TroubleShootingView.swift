import SwiftUI
import DeltaCore

/// An error which can occur during troubleshooting; how ironic.
enum TroubleshootingError: LocalizedError {
  case failedToDeleteCache
  case failedToResetConfig
  case failedToPerformFreshInstall

  var errorDescription: String? {
    switch self {
      case .failedToDeleteCache:
        return "Failed to delete cache directory."
      case .failedToResetConfig:
        return "Failed to reset configuration to defaults."
      case .failedToPerformFreshInstall:
        return "Failed to perform fresh install."
    }
  }
}

/// A collection of useful troubleshooting actions. Optionally displays a cause for
/// troubleshooting (in case the user was forcefully sent here).
struct TroubleshootingView: View {
  @EnvironmentObject var appState: StateWrapper<AppState>
  @EnvironmentObject var modal: Modal

  @Environment(\.storage) var storage: StorageDirectory

  @State private var message: String? = nil

  /// Content for a never-disappearing error message displayed above the option buttons.
  private let error: (any Error)?

  /// The error message to show if any.
  var errorMessage: String? {
    guard let error = error else {
      return nil
    }

    if let error = error as? RichError {
      return error.richDescription
    } else {
      return "\(error)"
    }
  }

  /// Creates a troubleshooting view with an optional cause for troubleshooting.
  init(error: (any Error)? = nil) {
    self.error = error
  }

  var body: some View {
    VStack {
      if let errorMessage = errorMessage {
        Text(errorMessage)
          .padding(.bottom, 10)
      }

      Button("Clear cache") { // Clear cache
        perform(
          "Clearing cache",
          "Cleared cache successfully",
          action: storage.removeCache,
          error: TroubleshootingError.failedToDeleteCache
        ) {
          message = nil
        }
      }.buttonStyle(SecondaryButtonStyle())

      Button("Reset config") { // Reset config
        perform(
          "Resetting config",
          "Reset config successfully",
          action: ConfigManager.default.resetConfig,
          error: TroubleshootingError.failedToResetConfig
        ) {
          message = nil
        }
      }.buttonStyle(SecondaryButtonStyle())

      Button("Perform fresh install") {
        perform(
          "Performing fresh install",
          action: {
            try storage.backup()
            try storage.reset()
            #if os(macOS)
              message = "Relaunching..."
              try await delay(seconds: 1)
              Utils.relaunch()
            #else
              message = "Please relaunch app to complete fresh install."
            #endif
          },
          error: TroubleshootingError.failedToPerformFreshInstall
        ) {
          message = nil
        }
      }.buttonStyle(SecondaryButtonStyle())

      #if os(macOS)
      Button("View logs") {
        NSWorkspace.shared.open(StorageManager.default.currentLogFile)
      }.buttonStyle(SecondaryButtonStyle())
      #endif

      if let message = message {
        Text(message)
          .padding(.top, 10)
      }
    }
    .frame(width: 200)
  }

  private func perform(
    _ taskName: String,
    _ successMessage: String? = nil,
    action: @escaping () async throws -> Void,
    error baseError: TroubleshootingError,
    onErrorDismissed errorDismissedHandler: (() -> Void)? = nil
  ) {
    Task {
      let initialMessage = "\(taskName)..."
      message = initialMessage
      do {
        try await delay(seconds: 0.5)
        try await action()
        if let successMessage = successMessage, message == initialMessage {
          message = successMessage
        }
      } catch {
        modal.error(baseError.becauseOf(error)) {
          errorDismissedHandler?()
        }
      }
    }
  }

  private func delay(seconds: Double) async throws {
    try await Task.sleep(nanoseconds: UInt64(Duration.seconds(seconds).nanoseconds))
  }
}
