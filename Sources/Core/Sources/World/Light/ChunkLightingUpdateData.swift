import Foundation

// TODO: just use the packet instead of this thing
public struct ChunkLightingUpdateData {
  public var trustEdges: Bool
  public var emptySkyLightSections: [Int]
  public var emptyBlockLightSections: [Int]
  public var skyLightArrays: [Int: [UInt8]]
  public var blockLightArrays: [Int: [UInt8]]
  
  public var updatedSections: [Int] {
    var sections: Set<Int> = []
    sections.formUnion(emptySkyLightSections)
    sections.formUnion(emptyBlockLightSections)
    sections.formUnion(skyLightArrays.keys)
    sections.formUnion(blockLightArrays.keys)
    return Array(sections)
  }
}
