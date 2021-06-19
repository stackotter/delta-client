//
//  AppState.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 19/6/21.
//

import Foundation
import DeltaCore

/// App states
enum AppState: Equatable {
  case launch
  case serverList
  case playServer(ServerDescriptor)
  case error(String)
  case fatalError(String)
}
