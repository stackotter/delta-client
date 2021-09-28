import Foundation
import simd

public struct AxisAlignedBoundingBox {
  public var position: simd_float3
  public var size: simd_float3
  
  public init(position: simd_float3, size: simd_float3) {
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
  
  public func getVertices() -> [simd_float3] {
    let bfl = position
    let bfr = position + simd_float3(size.x, 0, 0)
    let tfl = position + simd_float3(0, size.y, 0)
    let tfr = position + simd_float3(size.x, size.y, 0)
    
    let bbl = position + simd_float3(0, 0, size.z)
    let bbr = position + simd_float3(size.x, 0, size.z)
    let tbl = position + simd_float3(0, size.y, size.z)
    let tbr = position + simd_float3(size.x, size.y, size.z)
    
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
