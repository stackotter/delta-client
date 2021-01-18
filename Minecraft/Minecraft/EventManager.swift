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

// TODO: make this only for basic events
// packet handling will be better without this probably
// handlers can be registered for events and anyone who needs data from an event can just easily register a handler
class EventManager: Equatable {
  typealias EventHandler = (Event) -> Void
  
  let uuid = UUID()
  
  var eventHandlers: [String: [EventHandler]] = [:]
  var oneTimeEventHandlers: [String: [EventHandler]] = [:]
  
  var forwardTargets: [EventManager] = []
  
  // TODO: maybe make a few separate enums
  enum Event {
    case error(_ message: String)
    
    case connectionReady
    case connectionClosed
    
    case pingInfoReceived(PingInfo)
    
    case loginSuccess(packet: LoginSuccess)
    case loginDisconnect(reason: String)
    
    case joinGame(packet: JoinGamePacket)
    case setDifficulty(difficulty: Difficulty)
    case playerAbilities(packet: PlayerAbilitiesPacket)
    case hotbarSlotChange(slot: Int)
    case declareRecipes(recipeRegistry: RecipeRegistry)
    
    case chunkData(chunkData: ChunkData)
    
    case updateViewPosition(currentChunk: ChunkPosition)
    
    // HACK: this is quite a bodge and means a typo in an event name when registering a handler could go unnoticed and cause tons of annoying problems
    // TODO: write something to check if event with name exists before registering for now
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
  
  // registers an event handler to be called every time a specific an event in eventNames is triggered
  func registerEventHandler(_ handler: @escaping EventHandler, eventNames: [String]) {
    for eventName in eventNames {
      if eventHandlers[eventName] == nil {
        eventHandlers[eventName] = []
      }
      eventHandlers[eventName]!.append(handler)
    }
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
  
  func triggerEvent(_ event: Event, from: EventManager? = nil) {
    for forwardTarget in forwardTargets {
      if forwardTarget != from {
        forwardTarget.triggerEvent(event, from: self)
      }
    }
    
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
  
  func forward(to target: EventManager) {
    forwardTargets.append(target)
  }
  
  func link(with target: EventManager) {
    self.forward(to: target)
    target.forward(to: self)
  }
  
  static func == (lhs: EventManager, rhs: EventManager) -> Bool {
    return lhs.uuid == rhs.uuid
  }
}
