//
//  ServerDescriptor.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 20/1/21.
//

import Foundation

public struct ServerDescriptor: Equatable, Hashable, Codable, CustomStringConvertible {
  public var name: String
  public var host: String
  public var port: UInt16?
  
  public var description: String {
    if let port = port {
      return "\(host):\(port)"
    } else {
      return host
    }
  }
  
  public init(name: String, host: String, port: UInt16?) {
    self.name = name
    self.host = host
    self.port = port
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(host)
    hasher.combine(port)
  }
}
