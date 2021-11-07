import SwiftUI

// MARK: - TroubleShootingView


struct TroubleShootingView: View {
  // MARK: - Properties.observable
  
  
  @EnvironmentObject var appState: StateWrapper<AppState>
  @EnvironmentObject var loadingState: StateWrapper<LoadingState>
  @EnvironmentObject var popupState: StateWrapper<PopupState>
  
  
  // MARK: - Properties.UI
  
  
  /// Duration of `PopupView` transition animation
  private var popupAnimationDuration: Double = 0.3
  /// Content for a never-disappearing error message displayed above the option buttons
  private let staticErrorMessage: String?
  
  
  // MARK: - Properties.other
  
  
  private let taskQueue = DispatchQueue(label: "dev.stackotter.delta-client.troubleShootingTasks")
  
  
  // MARK: - Inits
  
  
  /// Class init
  ///
  /// - Parameter staticErrorMessage: content of the never-disappearing error essage to be displayed, if any
  init(staticErrorMessage: String? = nil) {
    self.staticErrorMessage = staticErrorMessage
  }
  
  
  // MARK: - Methods.View
  
  
  var body: some View {
    ZStack {
      // Troubleshooting options
      VStack {
        if let errorMessage = staticErrorMessage {
          Text(errorMessage)
            .padding(.bottom, 10)
        }
        
        Button("Clear cache") { // Clear cache
          displayBanner(with: "Confirm clear cache?") {
            clearCache(onSuccess: {
              appState.update(to: .settings(.troubleshooting))
              displayBannerWithAutodismiss(title: "Success", subtitle: "Cache cleared successfully")
            }, onFailure: { error in
              DeltaClientApp.modalError("Failed to delete cache directory; \(error)", safeState: .serverList)
            })
          }
        }.buttonStyle(SecondaryButtonStyle())
        
        Button("Reset config") { // Reset config
          displayBanner(with: "Confirm reset config?") {
            resetConfig(onSuccess: {
              appState.update(to: .settings(.troubleshooting))
              displayBannerWithAutodismiss(title: "Success", subtitle: "Config file reset successfully")
            }, onFailure: { error in
              DeltaClientApp.fatal("Failed to encode config: \(error)")
            })
          }
        }.buttonStyle(SecondaryButtonStyle())
        Button("Perform fresh install") {
          displayBanner(with: "Confirm perform fresh install?") {
            performFreshInstall { error in
              DeltaClientApp.fatal("Failed to perform fresh install: \(error)")
            }
          }
        }.buttonStyle(SecondaryButtonStyle())
      }
      .frame(width: 200)
      
      switch popupState.current {
        case .shown(let popupObject):
          PopupView(title: popupObject.title,
                    subtitle: popupObject.subtitle,
                    icon: popupObject.image,
                    action: popupObject.action)
            .transition(.move(edge: .top))
            .animation(.easeInOut(duration: popupAnimationDuration))
        case .hidden: EmptyView()
      }
    }
  }
  
  
  // MARK: - Methods.UI
  
  
  /// Displays a confirmation banner meant for the user to confirm their choice or discard it
  ///
  /// If the user confirms his choice, the `onConfirm` callback will be triggered, otherwise the banner will simply be dismissed
  /// - Postcondition: `popupState` updated to `.shown`
  /// - Parameters:
  ///   - title: the banner title
  ///   - onConfirm: callback triggered if the user confirms his choice
  private func displayBanner(with title: String, onConfirm: @escaping (() -> Void)) {
    func updateToShown() {
      popupState.update(to: .shown(
        PopupObject(
          title: "Warning",
          subtitle: title,
          image: Image(systemName: "exclamationmark.triangle"),
          action: (
            confirm: {
              popupState.update(to: .hidden)
              onConfirm()
            },
            cancel: { popupState.update(to: .hidden) }
          )
        )
      ))
    }
    
    switch popupState.current {
      case .hidden:
        updateToShown()
      case .shown(_):
        // Another alert is currently being displayed. Dismissing it first before displaying the new one
        popupState.update(to: .hidden)
        DispatchQueue.main.asyncAfter(deadline: .now() + popupAnimationDuration*1.1) {
          updateToShown()
        }
    }
  }
  
  /// Displays banner which dismisses by itself
  ///
  /// - Parameters:
  ///   - seconds: number of seconds after which the banner should disappear
  ///   - title: banner title
  ///   - subtitle: banner subtitle
  public func displayBannerWithAutodismiss(
    after seconds: Double = 3,
    title: String,
    subtitle: String,
    image: Image? = Image(systemName: "checkmark.seal")
  ) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      popupState.update(to: .shown(PopupObject(title: title,
                                               subtitle: subtitle,
                                               image: image
                                              )
                                  ))
      DispatchQueue.main.asyncAfter(deadline: .now() + 3) { // Dismissing success popup
        popupState.update(to: .hidden)
      }
    }
  }
  
  
  // MARK: - Methods.private
  
  
  /// Cleares the cache
  ///
  /// - Parameters:
  ///   - onSuccess: triggered if the clear cache operation is successful
  ///   - onFailure: triggered if the cache wasn't cleared
  private func clearCache(onSuccess: @escaping (() -> Void), onFailure: @escaping ((Error) -> Void)) {
    loadingState.update(to: .loadingWithMessage("Clearing cache"))
    
    // Executing with some delay in order for the user to read the "Clearing cache" screen
    taskQueue.asyncAfter(deadline: .now() + 1) {
      do {
        try StorageManager.default.clearCache()
        // Cache cleared successfully
        loadingState.update(to: .done)
        onSuccess()
      } catch let error {
        onFailure(error)
      }
    }
  }
  
  /// Resets current config
  ///
  /// - Parameters:
  ///   - onSuccess: triggered if the reset operation is successful
  ///   - onFailure: triggered if problems arose during the reset
  private func resetConfig(onSuccess: @escaping (() -> Void), onFailure: @escaping ((Error) -> Void)) {
    loadingState.update(to: .loadingWithMessage("Resetting config"))
    
    // Executing with some delay in order for the user to read the "Clearing cache" screen
    taskQueue.asyncAfter(deadline: .now() + 1) {
      do {
        try ConfigManager.default.resetConfig()
        loadingState.update(to: .done)
        onSuccess()
      } catch let error {
        onFailure(error)
      }
    }
  }
  
  /// Resets app to factory settings
  ///
  /// Relaunches the application if the operation is successful
  /// - Parameter onFailure: triggered if the operation didn't complete successfully
  private func performFreshInstall(onFailure: @escaping ((Error) -> Void)) {
    loadingState.update(to: .loadingWithMessage("Clearing out data"))
    
    taskQueue.asyncAfter(deadline: .now() + 1) {
      do {
        try StorageManager.default.factoryReset()
        loadingState.update(to: .loadingWithMessage("Data cleared. Relaunching..."))
        taskQueue.asyncAfter(deadline: .now() + 1) {
          Utils.relaunch()
        }
      } catch let error {
        onFailure(error)
      }
    }
  }
}
