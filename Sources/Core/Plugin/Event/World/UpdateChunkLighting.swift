import Foundation

extension World.Event {
  public struct UpdateChunkLighting: Event {
    public let position: ChunkPosition
    public let data: ChunkLightingUpdateData
    
    public init(position: ChunkPosition, data: ChunkLightingUpdateData) {
      self.position = position
      self.data = data
    }
  }
}
