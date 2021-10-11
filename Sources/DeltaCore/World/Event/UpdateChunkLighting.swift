import Foundation

extension World.Event {
  public struct UpdateChunkLighting: Event {
    let position: ChunkPosition
    let data: ChunkLightingUpdateData
  }
}
