//
//  AddChunk.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 31/5/21.
//

import Foundation

extension World.Event {
  struct AddChunk: Event {
    let position: ChunkPosition
    let chunk: Chunk
  }
}
