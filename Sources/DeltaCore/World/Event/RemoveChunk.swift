import Foundation

extension World.Event {
  public struct RemoveChunk: Event {
    let position: ChunkPosition
  }
}
