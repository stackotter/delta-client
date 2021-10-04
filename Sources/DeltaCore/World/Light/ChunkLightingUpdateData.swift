import Foundation

// TODO: just use the packet instead of this thing
public struct ChunkLightingUpdateData {
  public var trustEdges: Bool
  public var emptySkyLightSections: [Int]
  public var emptyBlockLightSections: [Int]
  public var skyLightArrays: [Int: [UInt8]]
  public var blockLightArrays: [Int: [UInt8]]
}
