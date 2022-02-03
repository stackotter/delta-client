extension World.Event {
  public struct ChunkComplete: Event {
    public let position: ChunkPosition
    
    public init(position: ChunkPosition) {
      self.position = position
    }
  }
}
