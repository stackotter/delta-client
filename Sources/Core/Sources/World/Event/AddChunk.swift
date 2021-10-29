import Foundation

extension World.Event {
  struct AddChunk: Event {
    let position: ChunkPosition
    let chunk: Chunk
  }
}
