//
//  NBTList.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 27/6/21.
//

import Foundation

// TODO: figure out how to not use Any
extension NBT {
  /// An array of unnamed NBT tags of the same type.
  public struct List: CustomStringConvertible {
    public var type: TagType
    public var list: [Any] = []
    
    public var description: String {
      return "\(list)"
    }
    
    public var count: Int {
      get {
        return list.count
      }
    }
    
    public mutating func append(_ elem: Any) {
      list.append(elem)
    }
  }
}
