//
//  InboundNetworkLayer.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 1/4/21.
//

import Foundation

public protocol InboundNetworkLayer {
  var inboundSuccessor: InboundNetworkLayer? { get set }
  
  func handleInbound(_ buffer: Buffer)
}
