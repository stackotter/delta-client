//
//  ModalState.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 27/6/21.
//

import Foundation

enum ModalState {
  case none
  case warning(String)
  case error(String, safeState: AppState?)
}
