extension Block.PhysicalMaterial: ProtobufCachable {
  public init(from message: ProtobufBlockPhysicalMaterial) {
    explosionResistance = message.explosionResistance
    slipperiness = message.slipperiness
    velocityMultiplier = message.velocityMultiplier
    jumpVelocityMultiplier = message.jumpVelocityMultiplier
    requiresTool = message.requiresTool
    hardness = message.hardness
  }
  
  public func cached() -> ProtobufBlockPhysicalMaterial {
    var message = ProtobufBlockPhysicalMaterial()
    message.explosionResistance = explosionResistance
    message.slipperiness = slipperiness
    message.velocityMultiplier = velocityMultiplier
    message.jumpVelocityMultiplier = jumpVelocityMultiplier
    message.requiresTool = requiresTool
    message.hardness = hardness
    return message
  }
}
