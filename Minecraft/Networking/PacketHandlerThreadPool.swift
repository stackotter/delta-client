//
//  PacketQueue.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation
import os

// handles multiple threads that handle packets simultaneously
// this doubled how fast my laptop loaded in chunks compared to the one thread i was using before (25 seconds vs 40 or more seconds)
// and that's with a spigot server, bungeecord, spotify and xcode running too
class PacketHandlerThreadPool {
  // TODO_LATER: move this to some sort of config file or constants file
  // 2 threads seems to be the sweet spot for my laptop, around 40% faster than one thread and not much slower than 3 threads
  // 3 threads starts using a lot more cpu for such little gain (almost 400% cpu at peak vs around 290% at peak)
  
  // TODO: implement threaded networking the way bixilon does it
  let numThreads = 1
  // using a set because no thread should be contained twice
  var threads: [DispatchQueue] = []
  
  // holds packets waiting to be processed
  var packetQueue: [(reader: PacketReader, state: PacketState)] = []
  // holds idle threads
  var availableThreads: Set<DispatchQueue> = []
  
  // used to access packetQueue
  var centralThread: DispatchQueue
  // thread used to manage the availableThreads array threadsafe-ly
  var threadManagementThread: DispatchQueue
  
  var eventManager: EventManager
  var locale: MinecraftLocale
  var packetRegistry: PacketRegistry
  var handler: (PacketReader, PacketState) -> Void
  
  init(eventManager: EventManager, locale: MinecraftLocale, packetRegistry: PacketRegistry) {
    self.eventManager = eventManager
    self.locale = locale
    self.packetRegistry = packetRegistry
    
    self.centralThread = DispatchQueue(label: "masterPacketHandlingThread")
    self.threadManagementThread = DispatchQueue(label: "packetHandlingThreadManagementThread") // nice naming, great job me :)
    
    for i in 0..<numThreads {
      let thread = DispatchQueue(label: "packetHandlingThread\(i)")
      self.threads.append(thread)
    }
    
    // all threads start idle
    self.availableThreads = Set(self.threads)
    
    // defaults to an empty handler
    self.handler = {
      (_ reader: PacketReader, _ state: PacketState) in
      return
    }
  }
  
  func setHandler(_ handler: @escaping (PacketReader, PacketState) -> Void) {
    self.handler = handler
  }
  
  // pops incoming packets onto the packetQueue and sets any idle threads going if necessary
  func handleBytes(_ bytes: [UInt8], state: PacketState) {
    centralThread.async {
      let reader = PacketReader(bytes: bytes, locale: self.locale)
      self.packetQueue.append((reader: reader, state: state))
      self.handlePackets()
    }
  }
  
  // sets as many idle threads going as possible (limited by number of packets on queue)
  private func handlePackets() {
    threadManagementThread.async {
      for thread in self.availableThreads {
        var shouldStop = false
        self.centralThread.sync {
          if self.packetQueue.count != 0 {
            let packet = self.packetQueue.removeFirst()
            // remove thread before starting async task to prevent a very unlikely race condition
            self.availableThreads.remove(thread)
            thread.async {
              self.handlePacket(packet, thread: thread)
            }
          } else {
            shouldStop = true
          }
        }
        if shouldStop {
          break
        }
      }
    }
  }
  
  // this is what is run in the thread pool to actually finally handle the packets
  private func handlePacket(_ packet: (reader: PacketReader, state: PacketState), thread: DispatchQueue) {
    handler(packet.reader, packet.state)
    
    // if there is an available packet, process it on this thread. otherwise, add this thread to availableThreads again.
    // this hopefully lets the work remain in the same one or two threads when there are less packets arriving (reduces thread switching)
    self.centralThread.sync {
      if self.packetQueue.count != 0 {
        let packet = self.packetQueue.removeFirst()
        thread.async {
          self.handlePacket(packet, thread: thread)
        }
      } else {
        threadManagementThread.async {
          self.availableThreads.insert(thread)
        }
      }
    }
  }
}
