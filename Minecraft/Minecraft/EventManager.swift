//
//  EventManager.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 20/12/20.
//

import Foundation

// INFO: the way the handlers dict is created is a bit dodge but swift might not have a better way at the moment.
//   the associated values make it difficult to compare cases cause enums can't have both associated values and raw values

// TODO: should probably use async for trigger event? gotta be careful not to create too many threads again tho
class EventManager {
  typealias EventHandler = (Event) -> Void
  
  var eventHandlers: [String: [EventHandler]] = [:]
  var oneTimeEventHandlers: [String: [EventHandler]] = [:]
  
  enum Event {
    case statusResponse(PingInfo)
    case loginSuccess
    
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
  
  func registerEventHandler(_ handler: @escaping EventHandler, eventNames: [String]) {
    for eventName in eventNames {
      if !eventHandlers.keys.contains(eventName) {
        eventHandlers[eventName] = []
      }
      eventHandlers[eventName]?.append(handler)
    }
  }
  
  func registerOneTimeHandler(_ handler: @escaping EventHandler, eventName: String) {
    if !oneTimeEventHandlers.keys.contains(eventName) {
      oneTimeEventHandlers[eventName] = []
    }
    oneTimeEventHandlers[eventName]?.append(handler)
  }
  
  func triggerEvent(event: Event) {
    let handlers = eventHandlers[event.name]
    if handlers != nil {
      for handler in handlers! {
        handler(event)
      }
    }
  }
}
