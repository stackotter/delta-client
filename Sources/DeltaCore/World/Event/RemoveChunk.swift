//
//  RemoveChunk.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 31/5/21.
//

import Foundation

extension World.Event {
  struct RemoveChunk: Event {
    let position: ChunkPosition
  }
}
