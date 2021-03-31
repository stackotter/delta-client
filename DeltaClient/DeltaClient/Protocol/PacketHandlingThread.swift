//
//  PacketHandlingThread.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation
import os

class PacketHandlingThread {
  var managementThread: DispatchQueue
  var packetThread: DispatchQueue
  var managementGroup: DispatchGroup
  
  // holds packets waiting to be processed
  var packetQueue: [PacketReader] = []
  
  var managers: Managers
  var locale: MinecraftLocale
  var packetRegistry: PacketRegistry
  var handler: (PacketReader) -> Void
  
  var isWaiting: Bool = true
  
  init(managers: Managers, packetRegistry: PacketRegistry) {
    self.managers = managers
    self.locale = managers.localeManager.currentLocale
    self.packetRegistry = packetRegistry
    
    self.managementThread = DispatchQueue(label: "packetHandlingManagement")
    self.managementGroup = DispatchGroup()
    self.packetThread = DispatchQueue(label: "packetHandling")
    
    // defaults to an empty handler
    // must be set using setHandler for any actual handling to happen
    self.handler = { reader in
      return
    }
  }
  
  func setHandler(_ handler: @escaping (PacketReader) -> Void) {
    self.handler = handler
  }
  
  // adds packet to end of queue and starts the handling loop again if it was waiting for more packets
  func handleBytes(_ bytes: [UInt8]) {
    let reader = PacketReader(bytes: bytes, locale: self.locale)
    managementThread.sync {
      self.packetQueue.append(reader)
    }
    newPacketCallback()
  }
  
  private func newPacketCallback() {
    if isWaiting {
      isWaiting = false
      handleNextPacket()
    }
  }
  
  private func handleNextPacket() {
    var queueLength = 0
    self.managementThread.sync {
      queueLength = self.packetQueue.count
      
      if queueLength != 0 {
        let packet = self.packetQueue.removeFirst()
        self.packetThread.async {
          self.handler(packet)
          self.handleNextPacket()
        }
      } else {
        self.isWaiting = true
      }
    }
  }
}
