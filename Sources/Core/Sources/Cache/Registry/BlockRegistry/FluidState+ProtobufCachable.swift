extension FluidState: ProtobufCachable {
  public init(from message: ProtobufBlockFluidState) {
    fluidId = Int(message.fluidID)
    height = Int(message.height)
    isWaterlogged = message.isWaterlogged
  }
  
  public func cached() -> ProtobufBlockFluidState {
    var message = ProtobufBlockFluidState()
    message.fluidID = Int32(fluidId)
    message.height = Int32(height)
    message.isWaterlogged = isWaterlogged
    return message
  }
}
