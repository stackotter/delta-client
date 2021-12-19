extension Block.SoundMaterial: ProtobufCachable {
  public init(from message: ProtobufBlockSoundMaterial) {
    volume = message.volume
    pitch = message.pitch
    breakSound = Int(message.breakSound)
    stepSound = Int(message.stepSound)
    placeSound = Int(message.placeSound)
    hitSound = Int(message.hitSound)
    fallSound = Int(message.fallSound)
  }
  
  public func cached() -> ProtobufBlockSoundMaterial {
    var message = ProtobufBlockSoundMaterial()
    message.volume = volume
    message.pitch = pitch
    message.breakSound = Int32(breakSound)
    message.stepSound = Int32(stepSound)
    message.placeSound = Int32(placeSound)
    message.hitSound = Int32(hitSound)
    message.fallSound = Int32(fallSound)
    return message
  }
}
