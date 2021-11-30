extension Block: ProtobufCachable {
  public init(from message: ProtobufBlock) throws {
    self.id = Int(message.id)
    self.vanillaParentBlockId = Int(message.vanillaParentBlockID)
    self.identifier = Identifier(
      namespace: message.identifierNamespace,
      name: message.identifierName)
    self.className = message.className
    
    self.fluidState = message.hasFluidState ? FluidState(from: message.fluidState) : nil
    self.tint = message.hasTint ? try Tint(from: message.tint) : nil
    self.offset = message.hasOffset ? try Offset(from: message.offset) : nil
    
    self.material = PhysicalMaterial(from: message.material)
    self.lightMaterial = LightMaterial(from: message.lightMaterial)
    self.soundMaterial = SoundMaterial(from: message.soundMaterial)
    self.shape = Shape(from: message.shape)
  }
  
  public func cached() -> ProtobufBlock {
    var message = ProtobufBlock()
    message.id = Int32(id)
    message.vanillaParentBlockID = Int32(vanillaParentBlockId)
    message.identifierNamespace = identifier.namespace
    message.identifierName = identifier.name
    message.className = className
    
    if let fluidState = fluidState {
      message.fluidState = fluidState.cached()
    }
    
    if let tint = tint {
      message.tint = tint.cached()
    }
    
    if let offset = offset {
      message.offset = offset.cached()
    }
    
    message.material = material.cached()
    message.lightMaterial = lightMaterial.cached()
    message.soundMaterial = soundMaterial.cached()
    message.shape = shape.cached()
    return message
  }
}
