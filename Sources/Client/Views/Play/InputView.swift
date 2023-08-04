import SwiftUI
import DeltaCore

final class InputDelegateWrapper {
  var delegate: InputDelegate?

  init(_ delegate: InputDelegate?) {
    self.delegate = delegate
  }
}

final class InputViewModel {
  var monitorsAdded = false
  var scrollWheelDeltaY: Float = 0
  #if os(macOS)
  var previousModifierFlags: NSEvent.ModifierFlags?
  #endif

  init() {}
}

struct InputView<Content: View>: View {
  private var delegateWrapper = InputDelegateWrapper(nil)
  private var content: (_ enabled: Binding<Bool>, _ setDelegate: (InputDelegate) -> Void) -> Content

  /// Whether or not this view is intercepting input events. Defaults to false.
  @State private var enabled = false

  private var model = InputViewModel()
  private var passthroughMouseClicks: Bool

  init(passthroughMouseClicks: Bool = false, @ViewBuilder _ content: @escaping (_ enabled: Binding<Bool>, _ setDelegate: (InputDelegate) -> Void) -> Content) {
    self.passthroughMouseClicks = passthroughMouseClicks
    self.content = content
  }

  func setDelegate(_ delegate: InputDelegate) {
    delegateWrapper.delegate = delegate
  }

  var body: some View {
    content($enabled, setDelegate)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      #if os(iOS)
      .gesture(TapGesture(count: 2).onEnded { _ in
        delegateWrapper.delegate?.onKeyDown(.escape)
      })
      .gesture(LongPressGesture(minimumDuration: 2, maximumDistance: 9).onEnded { _ in
        delegateWrapper.delegate?.onKeyDown(.f3)
      })
      .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global).onChanged { value in
        delegateWrapper.delegate?.onMouseMove(
          Float(value.translation.width),
          Float(value.translation.height)
        )
      })
      #endif
      #if os(macOS)
      .onAppear {
        if !model.monitorsAdded {
          NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged], handler: { event in
            if !enabled {
              return event
            }

            let deltaX = Float(event.deltaX)
            let deltaY = Float(event.deltaY)

            delegateWrapper.delegate?.onMouseMove(deltaX, deltaY)

            return event
          })

          NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel], handler: { event in
            if !enabled {
              return event
            }

            let deltaY = Float(event.scrollingDeltaY)
            delegateWrapper.delegate?.onScroll(deltaY)

            model.scrollWheelDeltaY += deltaY

            // TODO: Implement a scroll wheel sensitivity setting
            let threshold: Float = 0.5
            let key: Key
            if model.scrollWheelDeltaY >= threshold {
              key = .scrollUp
            } else if deltaY <= -threshold {
              key = .scrollDown
            } else {
              return nil
            }

            model.scrollWheelDeltaY = 0

            delegateWrapper.delegate?.onKeyDown(key)
            delegateWrapper.delegate?.onKeyUp(key)

            return nil
          })

          NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown, .leftMouseDown, .otherMouseDown], handler: { event in
            if !enabled {
              return event
            }

            if event.associatedEventsMask.contains(.leftMouseDown) {
              delegateWrapper.delegate?.onKeyDown(.leftMouseButton)
            }
            if event.associatedEventsMask.contains(.rightMouseDown) {
              delegateWrapper.delegate?.onKeyDown(.rightMouseButton)
            }
            if event.associatedEventsMask.contains(.otherMouseDown) {
              delegateWrapper.delegate?.onKeyDown(.otherMouseButton(event.buttonNumber))
            }

            return passthroughMouseClicks ? event : nil
          })

          NSEvent.addLocalMonitorForEvents(matching: [.rightMouseUp, .leftMouseUp, .otherMouseUp], handler: { event in
            if !enabled {
              return event
            }

            if event.associatedEventsMask.contains(.leftMouseUp) {
              delegateWrapper.delegate?.onKeyUp(.leftMouseButton)
            }
            if event.associatedEventsMask.contains(.rightMouseUp) {
              delegateWrapper.delegate?.onKeyUp(.rightMouseButton)
            }
            if event.associatedEventsMask.contains(.otherMouseUp) {
              delegateWrapper.delegate?.onKeyUp(.otherMouseButton(event.buttonNumber))
            }

            return passthroughMouseClicks ? event : nil
          })

          NSEvent.addLocalMonitorForEvents(matching: [.keyDown], handler: { event in
            if !enabled {
              return event
            }

            if let key = Key(keyCode: event.keyCode) {
              delegateWrapper.delegate?.onKeyDown(key, Array(event.characters ?? ""))

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
            if !enabled {
              return event
            }

            if let key = Key(keyCode: event.keyCode) {
              delegateWrapper.delegate?.onKeyUp(key)
            }
            return event
          })

          NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged], handler: { event in
            if !enabled {
              return event
            }

            let raw = Int32(event.modifierFlags.rawValue)
            let previousRaw = Int32(model.previousModifierFlags?.rawValue ?? 0)

            if raw & NX_DEVICELALTKEYMASK != 0 && previousRaw & NX_DEVICELALTKEYMASK == 0 {
              delegateWrapper.delegate?.onKeyDown(.leftOption, [])
            } else if raw & NX_DEVICELALTKEYMASK == 0 && previousRaw & NX_DEVICELALTKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.leftOption)
            }

            if raw & NX_DEVICELCMDKEYMASK != 0 && previousRaw & NX_DEVICELCMDKEYMASK == 0 {
              delegateWrapper.delegate?.onKeyDown(.leftCommand, [])
            } else if raw & NX_DEVICELCMDKEYMASK == 0 && previousRaw & NX_DEVICELCMDKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.leftCommand)
            }

            if raw & NX_DEVICELCTLKEYMASK != 0 && previousRaw & NX_DEVICELCTLKEYMASK == 0 {
              delegateWrapper.delegate?.onKeyDown(.leftControl, [])
            } else if raw & NX_DEVICELCTLKEYMASK == 0 && previousRaw & NX_DEVICELCTLKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.leftControl)
            }

            if raw & NX_DEVICELSHIFTKEYMASK != 0 && previousRaw & NX_DEVICELSHIFTKEYMASK == 0 {
              delegateWrapper.delegate?.onKeyDown(.leftShift, [])
            } else if raw & NX_DEVICELSHIFTKEYMASK == 0 && previousRaw & NX_DEVICELSHIFTKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.leftShift)
            }

            if raw & NX_DEVICERALTKEYMASK != 0 && previousRaw & NX_DEVICERALTKEYMASK == 0 {
              delegateWrapper.delegate?.onKeyDown(.rightOption, [])
            } else if raw & NX_DEVICERALTKEYMASK == 0 && previousRaw & NX_DEVICERALTKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.rightOption)
            }

            if raw & NX_DEVICERCMDKEYMASK != 0 && previousRaw & NX_DEVICERCMDKEYMASK == 0 {
              delegateWrapper.delegate?.onKeyDown(.rightCommand, [])
            } else if raw & NX_DEVICERCMDKEYMASK == 0 && previousRaw & NX_DEVICERCMDKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.rightCommand)
            }

            if raw & NX_DEVICERCTLKEYMASK != 0 && previousRaw & NX_DEVICERCTLKEYMASK == 0 {
              delegateWrapper.delegate?.onKeyDown(.rightControl, [])
            } else if raw & NX_DEVICERCTLKEYMASK == 0 && previousRaw & NX_DEVICERCTLKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.rightControl)
            }

            if raw & NX_DEVICERSHIFTKEYMASK != 0 && previousRaw & NX_DEVICERSHIFTKEYMASK == 0 {
              delegateWrapper.delegate?.onKeyDown(.rightShift, [])
            } else if raw & NX_DEVICERSHIFTKEYMASK == 0 && previousRaw & NX_DEVICERSHIFTKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.rightShift)
            }

            model.previousModifierFlags = event.modifierFlags

            return event
          })
        }
        model.monitorsAdded = true
      }
      #endif
  }
}
