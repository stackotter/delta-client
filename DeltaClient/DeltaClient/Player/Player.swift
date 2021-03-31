//
//  Player.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 15/1/21.
//

import Foundation

struct Player {
  var username: String
  
  var position: EntityPosition = EntityPosition(x: 0, y: 0, z: 0)
  var look: PlayerRotation = PlayerRotation(yaw: 0, pitch: 0)
  var chunkPosition: ChunkPosition = ChunkPosition(chunkX: 0, chunkZ: 0)
  
  var experienceBar: Float = -1
  var totalExperience: Int = -1
  var experienceLevel: Int = -1
  var health: Float = -1
  var food: Int = -1
  var saturation: Float = -1
  
  var hotbarSlot: Int8 = -1
  var flyingSpeed: Float = 0
  var fovModifier: Float = 0
  var flags: PlayerAbilities = PlayerAbilities()
  var isInvulnerable = false
  var isFlying = false
  var allowFlying = false
  var creativeMode = false // enables insta break?
  
  var gamemode: Gamemode = .none
  
  init(username: String) {
    self.username = username
  }
  
  mutating func updateFlags(to flags: PlayerAbilities) {
    isInvulnerable = flags.contains(.invulnerable)
    isFlying = flags.contains(.flying)
    allowFlying = flags.contains(.allowFlying)
    creativeMode = flags.contains(.creativeMode)
  }
}
