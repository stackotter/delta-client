import SwiftUI
import DeltaCore

struct InputView<Content: View>: View {
  @EnvironmentObject var modal: Modal
  @EnvironmentObject var appState: StateWrapper<AppState>

  @State var monitorsAdded = false
  @State var scrollWheelDeltaY: Float = 0

  #if os(macOS)
  @State var previousModifierFlags: NSEvent.ModifierFlags?
  #endif

  @Binding var listening: Bool

  private var content: () -> Content

  private var handleKeyRelease: ((Key) -> Void)?
  private var handleKeyPress: ((Key, [Character]) -> Void)?
  private var handleMouseMove: ((
    _ x: Float,
    _ y: Float,
    _ deltaX: Float,
    _ deltaY: Float
  ) -> Void)?
  private var handleScroll: ((_ deltaY: Float) -> Void)?
  private var shouldPassthroughClicks = false

  init(
    listening: Binding<Bool>,
    cursorCaptured: Bool,
    @ViewBuilder _ content: @escaping () -> Content
  ) {
    _listening = listening
    self.content = content

    if cursorCaptured {
      Self.captureCursor()
    } else {
      Self.releaseCursor()
    }
  }

  /// Captures the cursor (locks it in place and makes it invisible).
  private static func captureCursor() {
    #if os(macOS)
      CGAssociateMouseAndMouseCursorPosition(0)
      NSCursor.hide()
    #endif
  }

  /// Releases the cursor, making it visible and able to move around.
  private static func releaseCursor() {
    #if os(macOS)
      CGAssociateMouseAndMouseCursorPosition(1)
      NSCursor.unhide()
    #endif
  }

  /// If listening, the view will still process clicks, but the click will
  /// get passed through for the underlying view to process as well.
  func passthroughClicks(_ passthroughClicks: Bool = true) -> Self {
    with(\.shouldPassthroughClicks, passthroughClicks)
  }

  /// Adds an action to run when a key is released.
  func onKeyRelease(_ action: @escaping (Key) -> Void) -> Self {
    appendingAction(to: \.handleKeyRelease, action)
  }

  /// Adds an action to run when a key is pressed.
  func onKeyPress(_ action: @escaping (Key, [Character]) -> Void) -> Self {
    appendingAction(to: \.handleKeyPress, action)
  }

  /// Adds an action to run when the mouse is moved.
  func onMouseMove(_ action: @escaping (_ x: Float, _ y: Float, _ deltaX: Float, _ deltaY: Float) -> Void) -> Self {
    appendingAction(to: \.handleMouseMove, action)
  }

  /// Adds an action to run when scrolling occurs.
  func onScroll(_ action: @escaping (_ deltaY: Float) -> Void) -> Self {
    appendingAction(to: \.handleScroll, action)
  }

  func mousePositionInView(with geometry: GeometryProxy) -> (x: Float, y: Float)? {
    // This assumes that there's only one window and that this is only called once
    // the view's body has been evaluated at least once.
    guard let window = NSApplication.shared.orderedWindows.first else {
      return nil
    }

    let viewFrame = geometry.frame(in: .global)
    let x = (NSEvent.mouseLocation.x - window.frame.minX) - viewFrame.minX
    let y = window.frame.maxY - NSEvent.mouseLocation.y - viewFrame.minY
    return (Float(x), Float(y))
  }

  var body: some View {
    GeometryReader { geometry in
      contentWithEventListeners(geometry)
    }
  }

  func contentWithEventListeners(_ geometry: GeometryProxy) -> some View {
    // Make sure that the latest position is known to any observers (e.g. if
    // listening was disabled and now isn't, observers won't have been told
    // about any changes that occured during the period in which listening
    // was disabled).
    if let mousePosition = mousePositionInView(with: geometry) {
      handleMouseMove?(mousePosition.x, mousePosition.y, 0, 0)
    } else {
      modal.error("Failed to get mouse position (on demand)") {
        appState.update(to: .serverList)
      }
    }

    return content()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      #if os(iOS)
      .gesture(TapGesture(count: 2).onEnded { _ in
        handleKeyPress?(.escape, [])
      })
      .gesture(LongPressGesture(minimumDuration: 2, maximumDistance: 9).onEnded { _ in
        handleKeyPress?(.f3, [])
      })
      .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global).onChanged { value in
        handleMouseMove?(
          Float(value.translation.width),
          Float(value.translation.height)
        )
      })
      #endif
      #if os(macOS)
      .onDisappear {
        Self.releaseCursor()
      }
      .onAppear {
        if !monitorsAdded {
          NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged], handler: { event in
            if !listening {
              return event
            }

            guard let mousePosition = mousePositionInView(with: geometry) else {
              modal.error("Failed to get mouse position") {
                appState.update(to: .serverList)
              }
              return event
            }

            let x = mousePosition.x
            let y = mousePosition.y

            let deltaX = Float(event.deltaX)
            let deltaY = Float(event.deltaY)

            handleMouseMove?(x, y, deltaX, deltaY)

            return event
          })

          NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel], handler: { event in
            if !listening {
              return event
            }

            let deltaY = Float(event.scrollingDeltaY)
            handleScroll?(deltaY)

            scrollWheelDeltaY += deltaY

            // TODO: Implement a scroll wheel sensitivity setting
            let threshold: Float = 0.5
            let key: Key
            if scrollWheelDeltaY >= threshold {
              key = .scrollUp
            } else if deltaY <= -threshold {
              key = .scrollDown
            } else {
              return nil
            }

            scrollWheelDeltaY = 0

            handleKeyPress?(key, [])
            handleKeyRelease?(key)

            return nil
          })

          NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown, .leftMouseDown, .otherMouseDown], handler: { event in
            if !listening {
              return event
            }

            if event.associatedEventsMask.contains(.leftMouseDown) {
              handleKeyPress?(.leftMouseButton, [])
            }
            if event.associatedEventsMask.contains(.rightMouseDown) {
              handleKeyPress?(.rightMouseButton, [])
            }
            if event.associatedEventsMask.contains(.otherMouseDown) {
              handleKeyPress?(.otherMouseButton(event.buttonNumber), [])
            }

            return shouldPassthroughClicks ? event : nil
          })

          NSEvent.addLocalMonitorForEvents(matching: [.rightMouseUp, .leftMouseUp, .otherMouseUp], handler: { event in
            if !listening {
              return event
            }

            if event.associatedEventsMask.contains(.leftMouseUp) {
              handleKeyRelease?(.leftMouseButton)
            }
            if event.associatedEventsMask.contains(.rightMouseUp) {
              handleKeyRelease?(.rightMouseButton)
            }
            if event.associatedEventsMask.contains(.otherMouseUp) {
              handleKeyRelease?(.otherMouseButton(event.buttonNumber))
            }

            return shouldPassthroughClicks ? event : nil
          })

          NSEvent.addLocalMonitorForEvents(matching: [.keyDown], handler: { event in
            if !listening {
              return event
            }

            if let key = Key(keyCode: event.keyCode) {
              handleKeyPress?(key, Array(event.characters ?? ""))

              if key == .q && event.modifierFlags.contains(.command) {
                // Pass through quit command
                return event
              }

              if key == .f && event.modifierFlags.contains(.command) && event.modifierFlags.contains(.control) {
                // Pass through full screen command
                return event
              }
            }

            return nil
          })

          NSEvent.addLocalMonitorForEvents(matching: [.keyUp], handler: { event in
            if !listening {
              return event
            }

            if let key = Key(keyCode: event.keyCode) {
              handleKeyRelease?(key)
            }
            return event
          })

          NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged], handler: { event in
            if !listening {
              return event
            }

            let raw = Int32(event.modifierFlags.rawValue)
            let previousRaw = Int32(previousModifierFlags?.rawValue ?? 0)

            func check(_ key: Key, mask: Int32) {
              if raw & mask != 0 && previousRaw & mask == 0 {
                handleKeyPress?(key, [])
              } else if raw & mask == 0 && previousRaw & mask != 0 {
                handleKeyRelease?(key)
              }
            }

            check(.leftOption, mask: NX_DEVICELALTKEYMASK)
            check(.leftCommand, mask: NX_DEVICELCMDKEYMASK)
            check(.leftControl, mask: NX_DEVICELCTLKEYMASK)
            check(.leftShift, mask: NX_DEVICELSHIFTKEYMASK)
            check(.rightOption, mask: NX_DEVICERALTKEYMASK)
            check(.rightCommand, mask: NX_DEVICERCMDKEYMASK)
            check(.rightControl, mask: NX_DEVICERCTLKEYMASK)
            check(.rightShift, mask: NX_DEVICERSHIFTKEYMASK)

            previousModifierFlags = event.modifierFlags

            return event
          })
        }
        monitorsAdded = true
      }
      #endif
  }
}
