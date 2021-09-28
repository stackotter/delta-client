import Foundation

extension NBT {
  /// An NBT tag holds a name (unless in an NBT list), a type, and a value.
  public struct Tag: CustomStringConvertible {
    public var id: Int
    public var name: String?
    public var type: TagType
    public var value: Any?
    
    public var description: String {
      if value != nil {
        if value is Compound {
          return "\(value!)"
        }
        return "\"\(value!)\""
      } else {
        return "nil"
      }
    }
  }
}
