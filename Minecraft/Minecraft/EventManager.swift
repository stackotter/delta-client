//
//  EventManager.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 20/12/20.
//

import Foundation

// INFO: the way the handlers dict is created is a bit dodge but swift might not have a better way at the moment.
//   the associated values make it difficult to compare cases cause enums can't have both associated values and raw values

// NOTE: might not be threadsafe
class EventManager {
  typealias EventHandler = (Event) -> Void
  
  var eventHandlers: [String: [EventHandler]] = [:]
  var oneTimeEventHandlers: [String: [EventHandler]] = [:]
  
  enum Event {
    case pingInfoReceived(PingInfo)
    case loginSuccess
    
    case connectionReady
    case connectionClosed
    
    case error(_ message: String)
    
    // this computed property is used to create the keys for the handlers dict
    var name:String {
      let mirror = Mirror(reflecting: self)
      if let name = mirror.children.first?.label {
        return name
      } else {
        // if events are being funky this could possibly be a cause?
        // i don't think this line should ever be reached
        return String(describing:self)
      }
    }
  }
  
  // use for app-wide events such as errors
  func registerEventHandler(_ handler: @escaping EventHandler, eventNames: [String]) {
    for eventName in eventNames {
      if eventHandlers[eventName] == nil {
        eventHandlers[eventName] = []
      }
      eventHandlers[eventName]?.append(handler)
    }
  }
  
  // use to register temporary handlers for app-wide events
  func registerOneTimeEventHandler(_ handler: @escaping EventHandler, eventName: String) {
    if oneTimeEventHandlers[eventName] == nil {
      oneTimeEventHandlers[eventName] = []
    }
    oneTimeEventHandlers[eventName]!.append(handler)
  }
  
  // triggers an app wide error (so that the error can be shown by the swiftui code)
  func triggerError(_ message: String) {
    let error = Event.error(message)
    triggerEvent(event: error)
  }
  
  // triggers an event for handlers not attached to a specific server
  func triggerEvent(event: Event) {
    let handlers = eventHandlers[event.name]
    if handlers != nil {
      for handler in handlers! {
        handler(event)
      }
    }
    
    let oneTimeHandlers = oneTimeEventHandlers[event.name]
    if oneTimeHandlers != nil {
      for handler in oneTimeHandlers! {
        handler(event)
      }
      oneTimeEventHandlers[event.name] = nil
    }
  }
}
