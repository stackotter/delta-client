//
//  LoadingState.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 4/7/21.
//

import Foundation
import DeltaCore

enum LoadingState {
  case loading
  case loadingWithMessage(String)
  case error(String)
  case done(LoadedResources)
}
