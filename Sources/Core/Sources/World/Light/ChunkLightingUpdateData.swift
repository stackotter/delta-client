import Foundation

// TODO: just use the packet instead of this thing
public struct ChunkLightingUpdateData {
  public var trustEdges: Bool
  public var emptySkyLightSections: [Int]
  public var emptyBlockLightSections: [Int]
  public var skyLightArrays: [Int: [UInt8]]
  public var blockLightArrays: [Int: [UInt8]]
  
  public var updatedSections: [Int] {
    var sections: [Int] = []
    sections.append(contentsOf: emptySkyLightSections)
    sections.append(contentsOf: emptyBlockLightSections)
    sections.append(contentsOf: skyLightArrays.keys)
    sections.append(contentsOf: blockLightArrays.keys)
    return sections
  }
}
