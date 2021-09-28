//
//  ConnectionFailedEvent.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 6/7/21.
//

import Foundation
import Network

public struct ConnectionFailedEvent: Event {
  public var networkError: NWError
  
  public init(networkError: NWError) {
    self.networkError = networkError
  }
}
