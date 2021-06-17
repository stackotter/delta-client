//
//  EventManager.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 20/12/20.
//

import Foundation

class EventManager<T: EventProtocol> {
  typealias EventHandler = (Event) -> Void
  typealias Event = T
  
  let uuid = UUID()
  
  // event handlers for specific events
  var eventHandlers: [EventHandler] = []
  var specificEventHandlers: [String: [EventHandler]] = [:]
  var oneTimeEventHandlers: [String: [EventHandler]] = [:]
  
  var eventThread = DispatchQueue(label: "events")
  
  // registers an event handler to be called for every event
  func registerEventHandler(_ handler: @escaping EventHandler) {
    eventHandlers.append(handler)
  }
  
  // registers an event handler to be called every time a specific event is triggered
  func registerEventHandler(_ handler: @escaping EventHandler, eventName: String) {
    if specificEventHandlers[eventName] == nil {
      specificEventHandlers[eventName] = []
    }
    specificEventHandlers[eventName]!.append(handler)
  }
  
  // used to register temporary handlers
  func registerOneTimeEventHandler(_ handler: @escaping EventHandler, eventName: String) {
    if oneTimeEventHandlers[eventName] == nil {
      oneTimeEventHandlers[eventName] = []
    }
    oneTimeEventHandlers[eventName]!.append(handler)
  }
  
  // passes an event to all relevant handlers
  func triggerEvent(_ event: Event) {
    eventThread.async {
      for handler in self.eventHandlers {
        handler(event)
      }
      
      let specificHandlers = self.specificEventHandlers[event.name]
      if specificHandlers != nil {
        for handler in specificHandlers! {
          handler(event)
        }
      }
      
      let oneTimeHandlers = self.oneTimeEventHandlers[event.name]
      if oneTimeHandlers != nil {
        for handler in oneTimeHandlers! {
          handler(event)
        }
        self.oneTimeEventHandlers[event.name] = nil
      }
    }
  }
}
