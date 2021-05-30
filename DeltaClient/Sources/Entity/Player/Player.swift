//
//  Player.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 15/1/21.
//

import Foundation
import simd

struct Player {
  var username: String
  
  var spawnPosition = Position(x: 0, y: 0, z: 0)
  
  var position = EntityPosition(x: 0, y: 0, z: 0)
  var velocity = simd_double3(repeating: 0)
  var look = PlayerRotation(yaw: 0, pitch: 0)
  
  var experienceBar: Float = -1
  var totalExperience: Int = -1
  var experienceLevel: Int = -1
  var health: Float = -1
  var food: Int = -1
  var saturation: Float = -1
  
  var hotbarSlot: Int8 = -1
  var flyingSpeed: Float = 0
  var fovModifier: Float = 0
  var flags = PlayerAbilities()
  var isInvulnerable = false
  var isFlying = false
  var allowFlying = false
  var creativeMode = false // enables insta break?
  
  var gamemode: Gamemode = .none
  
  init(username: String) {
    self.username = username
  }
  
  mutating func update(with input: InputState) {
    // update look
    let sensitivity: Float = 0.35
    look.yaw += input.mouseDelta.x * sensitivity
    look.pitch += input.mouseDelta.y * sensitivity
    
    // clamp pitch
    if look.pitch < -90 {
      look.pitch = -90
    } else if look.pitch > 90 {
      look.pitch = 90
    }
    
    // wrap yaw to between 0 and 360 to avoid the yaw getting massive if someone is a ballerina
    let remainder = look.yaw.truncatingRemainder(dividingBy: 360)
    look.yaw = remainder < 0 ? 360 + remainder : remainder // find modulo from remainder
    
    Logger.debug("yaw: \(look.yaw)")
    
    // update velocity relative to yaw
    velocity = [0, 0, 0]
    if input.pressedKeys.contains(13) {
      velocity.z = PhysicsEngine.playerSpeed
    } else if input.pressedKeys.contains(1) {
      velocity.z = -PhysicsEngine.playerSpeed
    }
    
    if input.pressedKeys.contains(0) {
      velocity.x = PhysicsEngine.playerSpeed
    } else if input.pressedKeys.contains(2) {
      velocity.x = -PhysicsEngine.playerSpeed
    }
    
    if input.pressedKeys.contains(49) {
      velocity.y = PhysicsEngine.playerSpeed
    } else if input.modifierFlags.contains(.shift) {
      velocity.y = -PhysicsEngine.playerSpeed
    }
    
    if input.modifierFlags.contains(.control) {
      velocity *= 2
    }
    
    // adjust to real velocity (using yaw)
    let yawRadians = Double(look.yaw * .pi / 180)
    var xz = simd_double2(velocity.x, velocity.z)
    // swiftlint:disable shorthand_operator
    xz = xz * MatrixUtil.rotationMatrix2dDouble(yawRadians)
    // swiftlint:enable shorthand_operator
    velocity.x = xz.x
    velocity.z = xz.y // z is 2nd component of xz (y)
  }
  
  mutating func updateFlags(to flags: PlayerAbilities) {
    isInvulnerable = flags.contains(.invulnerable)
    isFlying = flags.contains(.flying)
    allowFlying = flags.contains(.allowFlying)
    creativeMode = flags.contains(.creativeMode)
  }
  
  func getEyePositon() -> EntityPosition {
    var eyePosition = position
    eyePosition.y += 1.625
    return eyePosition
  }
}
