import Foundation

public struct PixlyzerShapeRegistry: Decodable {
  public var shapes: [SingleOrMultiple<Int>]
  public var aabbs: [PixlyzerAABB]
}
