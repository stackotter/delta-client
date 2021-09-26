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
  case serverList
  case editServerList
  case accounts
  case login
  case directConnect
  case playServer(ServerDescriptor)
  case fatalError(String)
}
