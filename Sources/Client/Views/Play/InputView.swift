import SwiftUI

final class InputDelegateWrapper {
  var delegate: InputDelegate?
  
  init(_ delegate: InputDelegate?) {
    self.delegate = delegate
  }
}

final class InputViewModel {
  var monitorsAdded = false
  var previousModifierFlags: NSEvent.ModifierFlags?
  
  init() {}
}

struct InputView<Content: View>: View {
  private var delegateWrapper = InputDelegateWrapper(nil)
  private var content: (_ enabled: Binding<Bool>, _ setDelegate: (InputDelegate) -> Void) -> Content
  
  /// Whether or not this view is intercepting input events. Defaults to false.
  @State private var enabled = false
  
  private var model = InputViewModel()
  
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
          
          NSEvent.addLocalMonitorForEvents(matching: [.keyDown], handler: { event in
            if !enabled {
              return event
            }
            
            if let key = Key(keyCode: event.keyCode) {
              delegateWrapper.delegate?.onKeyDown(key)
              
              if key == .q && event.modifierFlags.contains(.command) {
                // Pass through quit command
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
              delegateWrapper.delegate?.onKeyDown(.leftOption)
            } else if raw & NX_DEVICELALTKEYMASK == 0 && previousRaw & NX_DEVICELALTKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.leftOption)
            }
            
            if raw & NX_DEVICELCMDKEYMASK != 0 && previousRaw & NX_DEVICELCMDKEYMASK == 0 {
              delegateWrapper.delegate?.onKeyDown(.leftCommand)
            } else if raw & NX_DEVICELCMDKEYMASK == 0 && previousRaw & NX_DEVICELCMDKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.leftCommand)
            }
            
            if raw & NX_DEVICELCTLKEYMASK != 0 && previousRaw & NX_DEVICELCTLKEYMASK == 0 {
              delegateWrapper.delegate?.onKeyDown(.leftControl)
            } else if raw & NX_DEVICELCTLKEYMASK == 0 && previousRaw & NX_DEVICELCTLKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.leftControl)
            }
            
            if raw & NX_DEVICELSHIFTKEYMASK != 0 && previousRaw & NX_DEVICELSHIFTKEYMASK == 0 {
              delegateWrapper.delegate?.onKeyDown(.leftShift)
            } else if raw & NX_DEVICELSHIFTKEYMASK == 0 && previousRaw & NX_DEVICELSHIFTKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.leftShift)
            }
            
            if raw & NX_DEVICERALTKEYMASK != 0 && previousRaw & NX_DEVICERALTKEYMASK == 0 {
              delegateWrapper.delegate?.onKeyDown(.rightOption)
            } else if raw & NX_DEVICERALTKEYMASK == 0 && previousRaw & NX_DEVICERALTKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.rightOption)
            }
            
            if raw & NX_DEVICERCMDKEYMASK != 0 && previousRaw & NX_DEVICERCMDKEYMASK == 0 {
              delegateWrapper.delegate?.onKeyDown(.rightCommand)
            } else if raw & NX_DEVICERCMDKEYMASK == 0 && previousRaw & NX_DEVICERCMDKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.rightCommand)
            }
            
            if raw & NX_DEVICERCTLKEYMASK != 0 && previousRaw & NX_DEVICERCTLKEYMASK == 0 {
              delegateWrapper.delegate?.onKeyDown(.rightControl)
            } else if raw & NX_DEVICERCTLKEYMASK == 0 && previousRaw & NX_DEVICERCTLKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.rightControl)
            }
            
            if raw & NX_DEVICERSHIFTKEYMASK != 0 && previousRaw & NX_DEVICERSHIFTKEYMASK == 0 {
              delegateWrapper.delegate?.onKeyDown(.rightShift)
            } else if raw & NX_DEVICERSHIFTKEYMASK == 0 && previousRaw & NX_DEVICERSHIFTKEYMASK != 0 {
              delegateWrapper.delegate?.onKeyUp(.rightShift)
            }
            
            model.previousModifierFlags = event.modifierFlags
            
            return event
          })
        }
        model.monitorsAdded = true
        #endif
      }
  }
}
