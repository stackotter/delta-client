//
//  UpdateChunk.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 12/6/21.
//

import Foundation

extension World.Event {
  struct UpdateChunk: Event {
    let position: ChunkPosition
    let data: UnpackedChunkData
  }
}
