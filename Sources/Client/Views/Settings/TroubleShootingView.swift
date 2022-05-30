import SwiftUI

struct TroubleshootingView: View {
  @EnvironmentObject var appState: StateWrapper<AppState>
  @EnvironmentObject var loadingState: StateWrapper<LoadingState>
  
  @State private var message: String? = nil
  
  /// Duration of `PopupView` transition animation
  private var popupAnimationDuration: Double = 0.3
  /// Content for a never-disappearing error message displayed above the option buttons
  private let fatalErrorMessage: String?
  /// The queue for running troubleshooting tasks.
  private let taskQueue = DispatchQueue(label: "dev.stackotter.delta-client.troublehootingTasks")
  
  /// - Parameter fatalErrorMessage: Content of a permanent error message to be displayed.
  init(fatalErrorMessage: String? = nil) {
    self.fatalErrorMessage = fatalErrorMessage
  }
  
  var body: some View {
    ZStack {
      // Troubleshooting options
      VStack {
        if let errorMessage = fatalErrorMessage {
          Text("Fatal: \(errorMessage)")
            .padding(.bottom, 10)
        }
        
        Button("Clear cache") { // Clear cache
          clearCache(onSuccess: {
            message = "Cache cleared successfully. Restart Delta Client for changes to take effect."
          }, onFailure: { error in
            DeltaClientApp.modalError("Failed to delete cache directory; \(error)", safeState: .settings(.troubleshooting))
          })
        }.buttonStyle(SecondaryButtonStyle())
        
        Button("Reset config") { // Reset config
          resetConfig(onSuccess: {
            message = "Config file reset successfully."
          }, onFailure: { error in
            DeltaClientApp.fatal("Failed to reset configuration to defaults: \(error)")
          })
        }.buttonStyle(SecondaryButtonStyle())
        
        Button("Perform fresh install") {
          performFreshInstall { error in
            DeltaClientApp.fatal("Failed to perform fresh install: \(error)")
          }
        }.buttonStyle(SecondaryButtonStyle())
        
        if let message = message {
          Text(message)
            .padding(.top, 10)
        }
      }
      .frame(width: 200)
    }
  }
  
  // MARK: Helper methods
  
  /// Clears the cache.
  /// - Parameters:
  ///   - onSuccess: triggered if the clear cache operation is successful
  ///   - onFailure: triggered if the cache wasn't cleared
  private func clearCache(onSuccess: @escaping () -> Void, onFailure: @escaping (Error) -> Void) {
    message = "Clearing cache..."
    
    // Executing with some delay in order for the user to read the "Clearing cache" screen
    taskQueue.asyncAfter(deadline: .now() + 0.5) {
      do {
        try StorageManager.default.clearCache()
        onSuccess()
      } catch let error {
        onFailure(error)
      }
    }
  }
  
  /// Resets the configuration to defaults.
  /// - Parameters:
  ///   - onSuccess: Triggered if the reset operation is successful.
  ///   - onFailure: Triggered if problems arose during the reset.
  private func resetConfig(onSuccess: @escaping () -> Void, onFailure: @escaping (Error) -> Void) {
    message = "Resetting config..."
    
    // Executing with some delay in order for the user to read the "Clearing cache" screen
    taskQueue.asyncAfter(deadline: .now() + 0.5) {
      do {
        try ConfigManager.default.resetConfig()
        onSuccess()
      } catch let error {
        onFailure(error)
      }
    }
  }
  
  /// Resets app to factory settings.
  ///
  /// Relaunches the application if the operation is successful.
  /// - Parameter onFailure: Triggered if the operation doesn't complete successfully.
  private func performFreshInstall(onFailure: @escaping (Error) -> Void) {
    message = "Clearing out data directory..."
    
    taskQueue.asyncAfter(deadline: .now() + 0.5) {
      do {
        try StorageManager.default.factoryReset()
        message = "Relaunching..."
        #if os(macOS)
        taskQueue.asyncAfter(deadline: .now() + 1) {
          Utils.relaunch()
        }
        #else
        message = "Please relaunch the app manually"
        #endif
      } catch let error {
        onFailure(error)
      }
    }
  }
}
