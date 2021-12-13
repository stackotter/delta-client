import SwiftUI

final class InputDelegateWrapper {
  var delegate: InputDelegate?
  
  init(_ delegate: InputDelegate?) {
    self.delegate = delegate
  }
}

struct InputView<Content: View>: View {
  private var delegateWrapper = InputDelegateWrapper(nil)
  private var content: (_ enabled: Binding<Bool>, _ setDelegate: (InputDelegate) -> Void) -> Content
  @State private var previousModifierFlags: NSEvent.ModifierFlags?
  @State private var monitorsAdded = false
  
  /// Whether or not this view is intercepting input events. Defaults to false.
  @State private var enabled = false
  
  init(@ViewBuilder _ content: @escaping (_ enabled: Binding<Bool>, _ setDelegate: (InputDelegate) -> Void) -> Content) {
    self.content = content
  }
  
  func setDelegate(_ delegate: InputDelegate) {
    delegateWrapper.delegate = delegate
  }
  
  var body: some View {
    content($enabled, setDelegate)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .onAppear {
        #if os(macOS)
        if !monitorsAdded {
          NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged], handler: { event in
            if !enabled {
              return event
            }
            
            let deltaX = Float(event.deltaX)
            let deltaY = Float(event.deltaY)
            
            delegateWrapper.delegate?.onMouseMove(deltaX, deltaY)
            
            return event
          })
          
          NSEvent.addLocalMonitorForEvents(matching: [.keyDown], handler: { event in
            if !enabled {
              return event
            }
            
            delegateWrapper.delegate?.onKeyDown(.code(Int(event.keyCode)))
            
            if event.keyCode == 12 && event.modifierFlags.contains(.command) {
              // Pass through quit command
              return event
            }
            
            return nil
          })
          
          NSEvent.addLocalMonitorForEvents(matching: [.keyUp], handler: { event in
            if !enabled {
              return event
            }
            
            delegateWrapper.delegate?.onKeyUp(.code(Int(event.keyCode)))
            return event
          })
          
          NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged], handler: { event in
            if !enabled {
              return event
            }
            
            let raw = Int32(event.modifierFlags.rawValue)
            let previousRaw = Int32(previousModifierFlags?.rawValue ?? 0)
            
            if raw & NX_DEVICELALTKEYMASK != 0 && previousRaw & NX_DEVICELALTKEYMASK == 0 {
              delegateWrapper.delegate?.onKeyDown(.modifier(.leftOption))
            } else if raw & NX_DEVICELALTKEYMASK == 0 && previousRaw & NX_DEVICELALTKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.modifier(.leftOption))
            }
            
            if raw & NX_DEVICELCMDKEYMASK != 0 && previousRaw & NX_DEVICELCMDKEYMASK == 0 {
              delegateWrapper.delegate?.onKeyDown(.modifier(.leftCommand))
            } else if raw & NX_DEVICELCMDKEYMASK == 0 && previousRaw & NX_DEVICELCMDKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.modifier(.leftCommand))
            }
            
            if raw & NX_DEVICELCTLKEYMASK != 0 && previousRaw & NX_DEVICELCTLKEYMASK == 0 {
              delegateWrapper.delegate?.onKeyDown(.modifier(.leftControl))
            } else if raw & NX_DEVICELCTLKEYMASK == 0 && previousRaw & NX_DEVICELCTLKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.modifier(.leftControl))
            }
            
            if raw & NX_DEVICELSHIFTKEYMASK != 0 && previousRaw & NX_DEVICELSHIFTKEYMASK == 0 {
              delegateWrapper.delegate?.onKeyDown(.modifier(.leftShift))
            } else if raw & NX_DEVICELSHIFTKEYMASK == 0 && previousRaw & NX_DEVICELSHIFTKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.modifier(.leftShift))
            }
            
            if raw & NX_DEVICERALTKEYMASK != 0 && previousRaw & NX_DEVICERALTKEYMASK == 0 {
              delegateWrapper.delegate?.onKeyDown(.modifier(.rightOption))
            } else if raw & NX_DEVICERALTKEYMASK == 0 && previousRaw & NX_DEVICERALTKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.modifier(.rightOption))
            }
            
            if raw & NX_DEVICERCMDKEYMASK != 0 && previousRaw & NX_DEVICERCMDKEYMASK == 0 {
              delegateWrapper.delegate?.onKeyDown(.modifier(.rightCommand))
            } else if raw & NX_DEVICERCMDKEYMASK == 0 && previousRaw & NX_DEVICERCMDKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.modifier(.rightCommand))
            }
            
            if raw & NX_DEVICERCTLKEYMASK != 0 && previousRaw & NX_DEVICERCTLKEYMASK == 0 {
              delegateWrapper.delegate?.onKeyDown(.modifier(.rightControl))
            } else if raw & NX_DEVICERCTLKEYMASK == 0 && previousRaw & NX_DEVICERCTLKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.modifier(.rightControl))
            }
            
            if raw & NX_DEVICERSHIFTKEYMASK != 0 && previousRaw & NX_DEVICERSHIFTKEYMASK == 0 {
              delegateWrapper.delegate?.onKeyDown(.modifier(.rightShift))
            } else if raw & NX_DEVICERSHIFTKEYMASK == 0 && previousRaw & NX_DEVICERSHIFTKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.modifier(.rightShift))
            }
            
            previousModifierFlags = event.modifierFlags
            
            return event
          })
        }
        monitorsAdded = true
        #endif
      }
  }
}
