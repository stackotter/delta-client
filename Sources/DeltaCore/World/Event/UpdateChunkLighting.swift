import Foundation

extension World.Event {
  struct UpdateChunkLighting: Event {
    let position: ChunkPosition
    let data: ChunkLightingUpdateData
  }
}
