//
//  AdvancementsPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation

struct AdvancementsPacket: ClientboundPacket {
  static let id: Int = 0x57
  
  var shouldReset: Bool
  var advancementMapping: [Identifier: Advancement]
  var toRemove: [Identifier]
  var progressMapping: [Identifier: AdvancementProgress]
  
  struct Advancement {
    var hasParent: Bool
    var parentId: Identifier?
    var hasDisplay: Bool
    var displayData: AdvancementDisplay?
    var criteria: [Identifier]
    var requirements: [[String]]
  }
  
  struct AdvancementDisplay {
    var title: ChatComponent
    var description: ChatComponent
    var icon: Slot
    var frameType: Int
    var flags: Int
    var backgroundTexture: Identifier?
    var xCoord: Float
    var yCoord: Float
  }
  
  struct AdvancementProgress {
    var criteria: [Identifier: CriterionProgress]
  }
  
  struct CriterionProgress {
    var achieved: Bool
    var dateOfAchieving: Int?
  }

  init(from packetReader: inout PacketReader) throws {
    shouldReset = packetReader.readBool()
    
    let mappingSize = packetReader.readVarInt()
    advancementMapping = [:]
    for _ in 0..<mappingSize {
      let key = try packetReader.readIdentifier()
      
      // read advancement
      let hasParent = packetReader.readBool()
      let parentId = hasParent ? try packetReader.readIdentifier() : nil
      let hasDisplay = packetReader.readBool()
      var displayData: AdvancementDisplay?
      if hasDisplay {
        let title = packetReader.readChat()
        let description = packetReader.readChat()
        let icon = try packetReader.readSlot()
        let frameType = packetReader.readVarInt()
        let flags = packetReader.readInt() // 0x1: has background texture, 0x2: show toast, 0x4: hidden
        let backgroundTexture = flags & 0x1 == 0x1 ? try packetReader.readIdentifier() : nil
        let xCoord = packetReader.readFloat()
        let yCoord = packetReader.readFloat()
        displayData = AdvancementDisplay(
          title: title, description: description, icon: icon, frameType: frameType,
          flags: flags, backgroundTexture: backgroundTexture, xCoord: xCoord, yCoord: yCoord
        )
      }
      
      let numCriteria = packetReader.readVarInt()
      var criteria: [Identifier] = []
      for _ in 0..<numCriteria {
        let criterion = try packetReader.readIdentifier()
        criteria.append(criterion)
      }

      let arrayLength = packetReader.readVarInt()
      var requirements: [[String]] = []
      for _ in 0..<arrayLength {
        let arrayLength2 = packetReader.readVarInt()
        var requirement: [String] = []
        for _ in 0..<arrayLength2 {
          let criterion = packetReader.readString()
          requirement.append(criterion)
        }
        requirements.append(requirement)
      }
      
      let value = Advancement(
        hasParent: hasParent, parentId: parentId, hasDisplay: hasDisplay,
        displayData: displayData, criteria: criteria, requirements: requirements
      )
      advancementMapping[key] = value
    }
    
    let listSize = packetReader.readVarInt()
    toRemove = []
    for _ in 0..<listSize {
      let identifier = try packetReader.readIdentifier()
      toRemove.append(identifier)
    }
    
    let progressSize = packetReader.readVarInt()
    progressMapping = [:]
    for _ in 0..<progressSize {
      let key = try packetReader.readIdentifier()
      
      // read advancement progress
      let size = packetReader.readVarInt()
      var criteria: [Identifier: CriterionProgress] = [:]
      for _ in 0..<size {
        let identifier = try packetReader.readIdentifier()
        
        // read criterion progress
        let achieved = packetReader.readBool()
        let dateOfAchieving = achieved ? packetReader.readLong() : nil
        
        let progress = CriterionProgress(achieved: achieved, dateOfAchieving: dateOfAchieving)
        criteria[identifier] = progress
      }
      
      let advancementProgress = AdvancementProgress(criteria: criteria)
      progressMapping[key] = advancementProgress
    }
  }
}
