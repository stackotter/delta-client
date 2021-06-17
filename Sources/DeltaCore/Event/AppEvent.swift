//
//  AppEvent.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 15/4/21.
//

import Foundation

enum AppEvent: EventProtocol {
  case error(_ message: String)
  
  case logout
  case leaveServer
  
  case loadingScreenMessage(_ message: String)
  case loadingComplete(_ managers: Managers)
  
  case downloadedTerrain
}
