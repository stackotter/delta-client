//
//  OutermostNetworkLayer.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 31/3/21.
//

import Foundation

public protocol OutermostNetworkLayer: OutboundNetworkLayer {
  var inboundSuccessor: InboundNetworkLayer? { get set }
  
  func connect()
  
  func disconnect()
}
