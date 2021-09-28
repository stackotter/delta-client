//
//  OutboundNetworkLayer.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 1/4/21.
//

import Foundation

public protocol OutboundNetworkLayer {
  var outboundSuccessor: OutboundNetworkLayer? { get set }
  
  func handleOutbound(_ buffer: Buffer)
}
