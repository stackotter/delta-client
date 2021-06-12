//
//  UpdateChunk.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 12/6/21.
//

import Foundation

extension World.Event {
  struct UpdateChunk: Event {
    var position: ChunkPosition
    var data: UnpackedChunkData
  }
}
