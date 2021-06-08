//
//  InteractiveMTKView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 30/5/21.
//

import Foundation
import MetalKit

class InteractiveMTKView: MTKView {
  var inputState = InputState()
  var mouseCaptured = false
  
  override var acceptsFirstResponder: Bool {
    return true
  }
  
  var trackingArea: NSTrackingArea?
  
  override func updateTrackingAreas() {
    if let trackingArea = trackingArea {
      self.removeTrackingArea(trackingArea)
    }
    
    let options: NSTrackingArea.Options = [
      .mouseEnteredAndExited,
      .mouseMoved,
      .activeWhenFirstResponder]
    let newTrackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
    
    self.addTrackingArea(newTrackingArea)
    trackingArea = newTrackingArea
  }
  
  override func keyDown(with event: NSEvent) {
    if event.isARepeat {
      return
    }
    
    inputState.pressedKeys.insert(event.keyCode)
  }
  
  override func keyUp(with event: NSEvent) {
    inputState.pressedKeys.remove(event.keyCode)
    
    // escape key releases mouse
    if event.keyCode == 53 {
      CGAssociateMouseAndMouseCursorPosition(1)
      NSCursor.unhide()
      mouseCaptured = false
    }
  }
  
  override func flagsChanged(with event: NSEvent) {
    inputState.modifierFlags = event.modifierFlags
  }
  
  override func mouseMoved(with event: NSEvent) {
    if mouseCaptured {
      inputState.mouseDelta += [
        Float(event.deltaX),
        Float(event.deltaY)
      ]
    }
  }
  
  override func mouseDown(with event: NSEvent) {
    // capture mouse on click
    CGAssociateMouseAndMouseCursorPosition(0)
    NSCursor.hide()
    mouseCaptured = true
  }
}
