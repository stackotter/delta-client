import Foundation

extension World.Event {
  struct RemoveChunk: Event {
    let position: ChunkPosition
  }
}
