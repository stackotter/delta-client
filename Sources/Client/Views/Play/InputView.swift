import SwiftUI
import DeltaCore

struct InputView<Content: View>: View {
  @State var monitorsAdded = false
  @State var scrollWheelDeltaY: Float = 0

  #if os(macOS)
  @State var previousModifierFlags: NSEvent.ModifierFlags?
  #endif

  @Binding var listening: Bool

  private var content: () -> Content

  private var onKeyRelease: ((Key) -> Void)?
  private var onKeyPress: ((Key, [Character]) -> Void)?
  private var onMouseMove: ((_ deltaX: Float, _ deltaY: Float) -> Void)?
  private var onScroll: ((_ deltaY: Float) -> Void)?
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
    CGAssociateMouseAndMouseCursorPosition(0)
    NSCursor.hide()
  }

  /// Releases the cursor, making it visible and able to move around.
  private static func releaseCursor() {
    CGAssociateMouseAndMouseCursorPosition(1)
    NSCursor.unhide()
  }

  /// If listening, the view will still process clicks, but the click will
  /// get passed through for the underlying view to process as well.
  func passthroughClicks(_ passthroughClicks: Bool = true) -> Self {
    with(\.shouldPassthroughClicks, passthroughClicks)
  }

  /// Adds an action to run when a key is released.
  func onKeyRelease(_ action: @escaping (Key) -> Void) -> Self {
    appendingAction(to: \.onKeyRelease, action)
  }

  /// Adds an action to run when a key is pressed.
  func onKeyPress(_ action: @escaping (Key, [Character]) -> Void) -> Self {
    appendingAction(to: \.onKeyPress, action)
  }

  /// Adds an action to run when the mouse is moved.
  func onMouseMove(_ action: @escaping (_ deltaX: Float, _ deltaY: Float) -> Void) -> Self {
    appendingAction(to: \.onMouseMove, action)
  }

  /// Adds an action to run when scrolling occurs.
  func onScroll(_ action: @escaping (_ deltaY: Float) -> Void) -> Self {
    appendingAction(to: \.onScroll, action)
  }

  var body: some View {
    content()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      #if os(iOS)
      .gesture(TapGesture(count: 2).onEnded { _ in
        onKeyPress?(.escape)
      })
      .gesture(LongPressGesture(minimumDuration: 2, maximumDistance: 9).onEnded { _ in
        onKeyPress?(.f3)
      })
      .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global).onChanged { value in
        onMouseMove?(
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

            let deltaX = Float(event.deltaX)
            let deltaY = Float(event.deltaY)

            onMouseMove?(deltaX, deltaY)

            return event
          })

          NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel], handler: { event in
            if !listening {
              return event
            }

            let deltaY = Float(event.scrollingDeltaY)
            onScroll?(deltaY)

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

            onKeyPress?(key, [])
            onKeyRelease?(key)

            return nil
          })

          NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown, .leftMouseDown, .otherMouseDown], handler: { event in
            if !listening {
              return event
            }

            if event.associatedEventsMask.contains(.leftMouseDown) {
              onKeyPress?(.leftMouseButton, [])
            }
            if event.associatedEventsMask.contains(.rightMouseDown) {
              onKeyPress?(.rightMouseButton, [])
            }
            if event.associatedEventsMask.contains(.otherMouseDown) {
              onKeyPress?(.otherMouseButton(event.buttonNumber), [])
            }

            return shouldPassthroughClicks ? event : nil
          })

          NSEvent.addLocalMonitorForEvents(matching: [.rightMouseUp, .leftMouseUp, .otherMouseUp], handler: { event in
            if !listening {
              return event
            }

            if event.associatedEventsMask.contains(.leftMouseUp) {
              onKeyRelease?(.leftMouseButton)
            }
            if event.associatedEventsMask.contains(.rightMouseUp) {
              onKeyRelease?(.rightMouseButton)
            }
            if event.associatedEventsMask.contains(.otherMouseUp) {
              onKeyRelease?(.otherMouseButton(event.buttonNumber))
            }

            return shouldPassthroughClicks ? event : nil
          })

          NSEvent.addLocalMonitorForEvents(matching: [.keyDown], handler: { event in
            if !listening {
              return event
            }

            if let key = Key(keyCode: event.keyCode) {
              onKeyPress?(key, Array(event.characters ?? ""))

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
              onKeyRelease?(key)
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
                onKeyPress?(key, [])
              } else if raw & mask == 0 && previousRaw & mask != 0 {
                onKeyRelease?(key)
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
