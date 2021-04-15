//
//  ServerEvent.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 15/4/21.
//

import Foundation

enum ServerEvent: EventProtocol {
  case connectionReady
  case connectionClosed
}
