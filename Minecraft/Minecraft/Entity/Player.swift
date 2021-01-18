//
//  Player.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 15/1/21.
//

import Foundation

struct Player {
  var username: String
  
  var position: EntityPosition
  var experience: Float
  var health: Int
  
  init(username: String) {
    self.username = username
    
    // default values (used until real values are received from the server)
    self.position = EntityPosition(x: 0, y: 0, z: 0)
    self.experience = -1
    self.health = -1
  }
}
