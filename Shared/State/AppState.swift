//
//  AppState.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 19/6/21.
//

import Foundation
import DeltaCore

/// App states
indirect enum AppState: Equatable {
  case launch
  case serverList
  case playServer(ServerDescriptor)
  case fatalError(String)
}
