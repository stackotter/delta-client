import Foundation

extension World.Event {
  public struct UpdateChunk: Event {
    let position: ChunkPosition
  }
}
