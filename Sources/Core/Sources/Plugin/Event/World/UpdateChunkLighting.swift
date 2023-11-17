import Foundation

extension World.Event {
  public struct UpdateChunkLighting: Event {
    public let position: ChunkPosition
    public let data: ChunkLightingUpdateData
  }
}
