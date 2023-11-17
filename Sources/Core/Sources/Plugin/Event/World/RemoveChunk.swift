import Foundation

extension World.Event {
  public struct RemoveChunk: Event {
    public let position: ChunkPosition
  }
}
