//
//  PingError.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 6/7/21.
//

import Foundation
import Network

public enum PingError: LocalizedError {
  case connectionFailed(NWError)
}
