import Foundation
import simd

public struct AxisAlignedBoundingBox {
  public var position: SIMD3<Float>
  public var size: SIMD3<Float>
  
  public init(position: SIMD3<Float>, size: SIMD3<Float>) {
    self.position = position
    self.size = size
  }
  
  public init(forChunkAt chunkPosition: ChunkPosition) {
    self.position = [
      Float(chunkPosition.chunkX * Chunk.width),
      0.0,
      Float(chunkPosition.chunkZ * Chunk.depth)]
    self.size = [
      Float(Chunk.width),
      Float(Chunk.height),
      Float(Chunk.depth)]
  }
  
  public init(forChunkSectionAt chunkSectionPosition: ChunkSectionPosition) {
    self.position = [
      Float(chunkSectionPosition.sectionX * Chunk.Section.width),
      Float(chunkSectionPosition.sectionY * Chunk.Section.height),
      Float(chunkSectionPosition.sectionZ * Chunk.Section.depth)]
    self.size = [
      Float(Chunk.Section.width),
      Float(Chunk.Section.height),
      Float(Chunk.Section.depth)]
  }
  
  public func getVertices() -> [SIMD3<Float>] {
    let bfl = position
    let bfr = position + SIMD3<Float>(size.x, 0, 0)
    let tfl = position + SIMD3<Float>(0, size.y, 0)
    let tfr = position + SIMD3<Float>(size.x, size.y, 0)
    
    let bbl = position + SIMD3<Float>(0, 0, size.z)
    let bbr = position + SIMD3<Float>(size.x, 0, size.z)
    let tbl = position + SIMD3<Float>(0, size.y, size.z)
    let tbr = position + SIMD3<Float>(size.x, size.y, size.z)
    
    return [
      bfl,
      bfr,
      tfl,
      tfr,
      bbl,
      bbr,
      tbl,
      tbr]
  }
}
