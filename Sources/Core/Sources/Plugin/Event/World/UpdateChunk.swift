import Foundation

extension World.Event {
  /// An event that is dispatched when the client receives a `ChunkDataPacket` for an existing chunk.
  public struct UpdateChunk: Event {
    /// The position of the updated chunk.
    public let position: ChunkPosition
    /// The sections that were updated by the chunk update.
    public let updatedSections: [Int]
  }
}
