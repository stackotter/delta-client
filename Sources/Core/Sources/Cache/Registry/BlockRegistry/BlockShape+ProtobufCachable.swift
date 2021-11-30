extension Block.Shape: ProtobufCachable {
  public init(from message: ProtobufBlockShape) {
    isDynamic = message.isDynamic
    isLarge = message.isLarge
    
    collisionShape = []
    collisionShape.reserveCapacity(message.collisionShape.count)
    for aabb in message.collisionShape {
      collisionShape.append(AxisAlignedBoundingBox(from: aabb))
    }
    
    outlineShape = []
    outlineShape.reserveCapacity(message.outlineShape.count)
    for aabb in message.outlineShape {
      outlineShape.append(AxisAlignedBoundingBox(from: aabb))
    }
    
    if message.hasOcclusionShapeIds {
      var ids: [Int] = []
      ids.reserveCapacity(message.occlusionShapeIds.ids.count)
      for id in message.occlusionShapeIds.ids {
        ids.append(Int(id))
      }
      occlusionShapeIds = ids
    }
    
    if message.hasIsSturdy {
      isSturdy = message.isSturdy.values
    }
  }
  
  public func cached() -> ProtobufBlockShape {
    var message = ProtobufBlockShape()
    message.isDynamic = isDynamic
    message.isLarge = isLarge
    
    message.collisionShape.reserveCapacity(collisionShape.count)
    for aabb in collisionShape {
      message.collisionShape.append(aabb.cached())
    }
    
    message.outlineShape.reserveCapacity(outlineShape.count)
    for aabb in outlineShape {
      message.outlineShape.append(aabb.cached())
    }
    
    if let occlusionShapeIds = occlusionShapeIds {
      message.occlusionShapeIds.ids.reserveCapacity(occlusionShapeIds.count)
      for id in occlusionShapeIds {
        message.occlusionShapeIds.ids.append(Int32(id))
      }
    }
    
    if let isSturdyValues = isSturdy {
      message.isSturdy.values = isSturdyValues
    }
    
    return message
  }
}

