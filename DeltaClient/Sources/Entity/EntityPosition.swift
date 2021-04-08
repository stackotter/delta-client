//
//  EntityPosition.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 15/1/21.
//

import Foundation

struct EntityPosition {
  var x: Double
  var y: Double
  var z: Double
  
  var chunkPosition: ChunkPosition {
    let chunkX = Int((x/16).rounded(.down))
    let chunkZ = Int((z/16).rounded(.down))
    
    return ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
  }
}
