import Foundation

extension World.Event {
  struct UpdateChunk: Event {
    let position: ChunkPosition
  }
}
