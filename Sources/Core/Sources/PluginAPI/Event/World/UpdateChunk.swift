import Foundation

extension World.Event {
  public struct UpdateChunk: Event {
    public let position: ChunkPosition
    
    public init(position: ChunkPosition) {
      self.position = position
    }
  }
}
