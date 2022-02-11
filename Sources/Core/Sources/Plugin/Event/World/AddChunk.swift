extension World.Event {
  public struct AddChunk: Event {
    public let position: ChunkPosition
    
    public init(position: ChunkPosition) {
      self.position = position
    }
  }
}
