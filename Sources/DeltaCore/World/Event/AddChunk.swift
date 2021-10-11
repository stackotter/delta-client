import Foundation

extension World.Event {
  public struct AddChunk: Event {
    let position: ChunkPosition
    let chunk: Chunk
  }
}
