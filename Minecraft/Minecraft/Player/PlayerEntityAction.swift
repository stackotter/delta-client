//
//  PlayerEntityAction.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

enum PlayerEntityAction: Int32 {
  case startSneaking = 0
  case stopSneaking = 1
  case leaveBed = 2
  case startSprinting = 3
  case stopSprinting = 4
  case startHorseJump = 5
  case stopHorseJump = 6
  case openHorseInventory = 7
  case startElytraFlying = 8
}
