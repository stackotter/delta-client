import SwiftUI
import DeltaCore
import DeltaRenderer
import Combine

enum GameState {
  case playing
  case gpuFrameCaptureComplete(file: URL)
}

enum OverlayState {
  case menu
  case settings
}

class Box<T> {
  var value: T

  init(_ initialValue: T) {
    self.value = initialValue
  }
}

/// Where the real Minecraft stuff happens. This handles everything after you choose
/// a server to join.
struct GameView: View {
  @EnvironmentObject var appState: StateWrapper<AppState>
  @EnvironmentObject var managedConfig: ManagedConfig
  @EnvironmentObject var modal: Modal
  @Environment(\.storage) var storage: StorageDirectory

  @StateObject var state = StateWrapper<GameState>(initial: .playing)
  @StateObject var overlayState = StateWrapper<OverlayState>(initial: .menu)

  @State var pressedKeys: Set<Key> = []
  @State var showInGameMenu = false
  @State var inputCaptured = true
  @State var cursorCaptured = true
  
  var serverDescriptor: ServerDescriptor

  var body: some View {
    JoinServerAndThen(serverDescriptor) { client in
      WithRenderCoordinator(for: client) { renderCoordinator in
        VStack {
          switch state.current {
            case .playing:
              ZStack {
                WithCurrentController {
                  InputView(listening: $inputCaptured, cursorCaptured: cursorCaptured) {
                    gameView(renderCoordinator: renderCoordinator)
                  }
                  .onKeyPress { [weak client] key, characters in
                    pressedKeys.insert(key)
                    client?.press(key, characters)
                  }
                  .onKeyRelease { [weak client] key in
                    pressedKeys.remove(key)
                    client?.release(key)
                  }
                  .onMouseMove { [weak client] deltaX, deltaY in
                    // TODO: Formalise this adjustment factor somewhere
                    let sensitivityAdjustmentFactor: Float = 0.004
                    let sensitivity = sensitivityAdjustmentFactor * managedConfig.mouseSensitivity
                    client?.moveMouse(sensitivity * deltaX, sensitivity * deltaY)
                  }
                  .passthroughClicks(!cursorCaptured)
                }
                .onButtonPress { [weak client] button in
                  guard let input = input(for: button) else {
                    return
                  }
                  client?.press(input)
                }
                .onButtonRelease { [weak client] button in
                  guard let input = input(for: button) else {
                    return
                  }
                  client?.release(input)
                }
                .onThumbstickMove { [weak client] thumbstick, x, y in
                  switch thumbstick {
                    case .left:
                      client?.moveLeftThumbstick(x, y)
                    case .right:
                      client?.moveRightThumbstick(x, y)
                  }
                }

                overlayView
              }
            case .gpuFrameCaptureComplete(let file):
              frameCaptureResult(file)
          }
        }
        .onAppear {
          modal.onError { [weak client] _ in
            client?.game.tickScheduler.cancel()
            cursorCaptured = false
            inputCaptured = false
          }

          registerEventHandler(client, renderCoordinator)
        }
      }
    } cancellationHandler: {
      appState.update(to: .serverList)
    }
  }

  func registerEventHandler(_ client: Client, _ renderCoordinator: RenderCoordinator) {
    client.eventBus.registerHandler { event in
      switch event {
        case _ as OpenInGameMenuEvent:
          showInGameMenu = true
          cursorCaptured = false
          inputCaptured = false
        case _ as ReleaseCursorEvent:
          cursorCaptured = false
        case _ as CaptureCursorEvent:
          cursorCaptured = true
        case let event as KeyPressEvent where event.input == .performGPUFrameCapture:
          let outputFile = storage.uniqueGPUCaptureFile()
          do {
            try renderCoordinator.captureFrames(count: 10, to: outputFile)
          } catch {
            modal.error(RichError("Failed to start frame capture").becauseOf(error))
          }
        case let event as FinishFrameCaptureEvent:
          cursorCaptured = false
          inputCaptured = false
          state.update(to: .gpuFrameCaptureComplete(file: event.file))
        default:
          break
      }
    }
  }

  func gameView(renderCoordinator: RenderCoordinator) -> some View {
    ZStack {
      // Renderer
      if #available(macOS 13, iOS 16, *) {
        MetalView(renderCoordinator: renderCoordinator)
          .onAppear {
            cursorCaptured = true
            inputCaptured = true
          }
      }
      else {
        MetalViewClass(renderCoordinator: renderCoordinator)
          .onAppear {
            cursorCaptured = true
            inputCaptured = true
          }
      }

      #if os(iOS)
      movementControls
      #endif
    }
  }

  /// Gets the input associated with a particular controller button.
  func input(for button: Controller.Button) -> Input? {
    switch button {
      case .buttonA:
        return .jump
      case .leftTrigger:
        return .place
      case .rightTrigger:
        return .destroy
      case .leftShoulder:
        return .previousSlot
      case .rightShoulder:
        return .nextSlot
      case .leftThumbstickButton:
        return .sprint
      case .buttonB:
        return .sneak
      case .dpadUp:
        return .changePerspective
      case .dpadRight:
        return .openChat
      default:
        return nil
    }
  }

  func frameCaptureResult(_ file: URL) -> some View {
    VStack {
      Text("GPU frame capture complete")

      Group {
        #if os(macOS)
        Button("Show in finder") {
          NSWorkspace.shared.activateFileViewerSelecting([file])
        }.buttonStyle(SecondaryButtonStyle())
        #elseif os(iOS)
        // TODO: Add a file sharing menu for iOS
        Text("I have no clue how to get hold of the file")
        #else
        #error("Unsupported platform, no file opening method")
        #endif

        Button("OK") {
          state.pop()
        }.buttonStyle(PrimaryButtonStyle())
      }.frame(width: 200)
    }
  }

  func openMenu() {
    inputCaptured = false
    cursorCaptured = false
    showInGameMenu = true
  }

  func closeMenu() {
    inputCaptured = true
    cursorCaptured = true
    showInGameMenu = false
  }

  /// In-game menu overlay.
  var overlayView: some View {
    VStack {
      if showInGameMenu {
        GeometryReader { geometry in
          VStack {
            switch overlayState.current {
              case .menu:
                VStack {
                  Button("Back to game", action: closeMenu)
                    .keyboardShortcut(.escape, modifiers: [])
                    .buttonStyle(PrimaryButtonStyle())
                  Button("Settings") { overlayState.update(to: .settings) }
                    .buttonStyle(SecondaryButtonStyle())
                  Button("Disconnect", action: disconnect)
                    .buttonStyle(SecondaryButtonStyle())
                }
                .frame(width: 200)
              case .settings:
                SettingsView(isInGame: true, onDone: {
                  overlayState.update(to: .menu)
                })
            }
          }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color.black.opacity(0.702), alignment: .center)
        }
      }
    }
  }

  #if os(iOS)
  var movementControls: some View {
    VStack {
      Spacer()
      HStack {
        HStack(alignment: .bottom) {
          movementControl("a", .strafeLeft)
          VStack {
            movementControl("w", .moveForward)
            movementControl("s", .moveBackward)
          }
          movementControl("d", .strafeRight)
        }
        Spacer()
        VStack {
          movementControl("*", .jump)
          movementControl("_", .sneak)
        }
      }
    }
  }

  func movementControl(_ label: String, _ input: Input) -> some View {
    return ZStack {
      Color.blue.frame(width: 50, height: 50)
      Text(label)
    }.onLongPressGesture(
      minimumDuration: 100000000000,
      maximumDistance: 50,
      perform: { return },
      onPressingChanged: { isPressing in
        if isPressing {
          model.client.press(input)
        } else {
          model.client.release(input)
        }
      }
    )
  }
  #endif

  func disconnect() {
    appState.update(to: .serverList)
  }
}
