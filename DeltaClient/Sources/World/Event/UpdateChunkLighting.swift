//
//  UpdateChunkLighting.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/6/21.
//

import Foundation

extension World.Event {
  struct UpdateChunkLighting: Event {
    let position: ChunkPosition
    let data: ChunkLightingUpdateData
  }
}
