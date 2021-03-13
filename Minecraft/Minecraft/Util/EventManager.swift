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

// packet handling will be better without this probably
// handlers can be registered for events and anyone who needs data from an event can just easily register a handler
class EventManager: Equatable {
  typealias EventHandler = (Event) -> Void
  
  let uuid = UUID()
  
  // event handlers for specific events
  var eventHandlers: [EventHandler] = []
  var specificEventHandlers: [String: [EventHandler]] = [:]
  var oneTimeEventHandlers: [String: [EventHandler]] = [:]
  
  var forwardTargets: [EventManager] = []
  
  enum Event {
    case error(_ message: String)
    
    case connectionReady
    case connectionClosed
    
    case downloadedTerrain
    
    case loadingScreenMessage(_ message: String)
    case loadingComplete(_ managers: Managers)
    
    // this computed property is used to create the keys for the handlers dict
    var name:String {
      let mirror = Mirror(reflecting: self)
      if let name = mirror.children.first?.label {
        return name
      } else {
        return String(describing:self)
      }
    }
  }
  
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
  
  // convenience function for triggering errors easily
  func triggerError(_ message: String, from: EventManager? = nil) {
    let error = Event.error(message)
    triggerEvent(error)
  }
  
  // passes an event to all relevant handlers
  func triggerEvent(_ event: Event, from: EventManager? = nil) {
    for forwardTarget in forwardTargets {
      if forwardTarget != from {
        forwardTarget.triggerEvent(event, from: self)
      }
    }
    
    for handler in eventHandlers {
      handler(event)
    }
    
    let specificHandlers = specificEventHandlers[event.name]
    if specificHandlers != nil {
      for handler in specificHandlers! {
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
  
  // adds an eventmanager that this eventmanager will forward all its events to (after first handling them itself)
  func forward(to target: EventManager) {
    forwardTargets.append(target)
  }
  
  // sets two way forwarding between two eventmanagers
  // events triggered in either will be handled by both.
  func link(with target: EventManager) {
    self.forward(to: target)
    target.forward(to: self)
  }
  
  static func == (lhs: EventManager, rhs: EventManager) -> Bool {
    return lhs.uuid == rhs.uuid
  }
}
